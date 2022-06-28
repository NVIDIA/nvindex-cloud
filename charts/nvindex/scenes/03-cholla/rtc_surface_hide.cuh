/******************************************************************************
 * Copyright 2020 NVIDIA Corporation. All rights reserved.
 *****************************************************************************/

// # RTC Kernel:
// ** Hide Surface Rendering **

// # Summary: 
// Displays nothing

NV_IDX_XAC_VERSION_1_0

using namespace nv::index::xac;
using namespace nv::index::xaclib;

class Surface_sample_program 
{
    NV_IDX_SURFACE_SAMPLE_PROGRAM

public:
    NV_IDX_DEVICE_INLINE_MEMBER
    void initialize() {}

    NV_IDX_DEVICE_INLINE_MEMBER
    int execute(
        const   Sample_info_self&  sample_info,        // read-only
                Sample_output&     sample_output)       // write-only
    {
        // Return program success
        return NV_IDX_PROG_DISCARD_SAMPLE;
    }

}; // class Surface_sample_program
