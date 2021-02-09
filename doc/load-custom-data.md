# Loading your own Data

It's possible and quite easy to load your own dataset, as long as it's in a raw or VDS format.

## Scene file

The NVIDIA IndeX viewer works through simple key-value base text files called projects. Just place your data in a convenient location (s3 bucket or local disk) and use one of the [raw](../resources/scene_template_raw.prj) or [vds](../resources/scene_template_vds.prj) template files. For a quick start, you only have to fill in the path and data size.

Please note that you have to store your data in a shared location with the compute nodes when using ParallelCluster.

## Starting IndeX

To load your custom scene you only have to add `--add myscene.prj` when starting the viewer. For example:

```sh
./nvindex-viewer.sh --add myscene.prj
```
