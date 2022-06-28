import websocket
import random
import logging
import sys
import json
import base64
import ssl
import time


logging.basicConfig(stream=sys.stdout, level=logging.INFO)


def get_websocket(ws_cmd_url, credentials=None):
    """ Generate a WebSocket connection to the service """
    if credentials:
        b64 = base64.b64encode(f"{credentials[0]}:{credentials[1]}".encode()).decode("ascii")
        header = {"Authorization": f"Basic {b64}"}
    else:
        header = {}

    return websocket.create_connection(ws_cmd_url, suppress_origin=True, header=header, sslopt={"cert_reqs": ssl.CERT_NONE})


def send_jsonrpc_command(websocket: websocket.WebSocket, cmd: dict) -> tuple[bool, dict]:
    """ Send a jsonrpc command, wait for the response and return it. """

    cmd_id = random.randint(10000, 90000)
    cmd_json = {
        "jsonrpc": "2.0",
        "id": cmd_id,
        **cmd
    }

    logging.debug(f"sending cmd: {cmd} id: {cmd_id}")
    websocket.send(json.dumps(cmd_json))

    while True:
        ret = websocket.recv()
        ret_json = json.loads(ret)
        if ret_json["id"] == cmd_id:
            return "result" in ret_json, ret_json
        else:
            # print('waiting for ', my_cmd_id)
            pass


def wait_for_data_to_load(websocket: websocket.WebSocket, retries=60*10, sleep_time_s=2) -> bool:
    cmd_json = {
        "method": "nv::index::app::perflab.get_performance_value",
        "params": {
            "query_performance_key_list": False,
            "query_performance_value": ["nb_subcubes_rendered", "frames_per_second"]
        }
    }

    while retries > 0:
        _, res = send_jsonrpc_command(websocket, cmd_json)
        values = res.get("result", {}).get("performance_value", {})
        if int(values.get("nb_subcubes_rendered", 0)) > 0 and float(values.get("frames_per_second", 0.0)) > 2.5:
            return True

        time.sleep(sleep_time_s)
    
    return False
