/******************************************************************************
 * Copyright 2019 NVIDIA Corporation. All rights reserved.
 *****************************************************************************/

NV_IDX_XAC_VERSION_1_0

// Slots must match the active IRendering_kernel_program_scene_element_mapping attribute
#define SLOT_VOLUME_1   1
#define SLOT_VOLUME_2   2

#define SLOT_CMAP_1     3
#define SLOT_CMAP_2     4

using namespace nv::index::xac;
using namespace nv::index::xaclib;

class Volume_sample_program
{
    NV_IDX_VOLUME_SAMPLE_PROGRAM

public:
    
    // default field index
    const uint field_id     = 0u;
    float gamma_c0          = 1.0f;
    float gamma_c1          = 1.0f;

    const float min_c1_alpha      = 0.001f;
    const float max_c1_scale      = 4.0f;

    const float3 filter_dim = make_float3(3);
    const float3 filter_offset = make_float3(0.3f);

    NV_IDX_DEVICE_INLINE_MEMBER
    void initialize() 
    {
        // bin buffer from slot 1
        //const float * buffer1 = state.bind_parameter_buffer<float>(1);
        gamma_c0 = 0.564 * 2.0f;

        //const float * buffer2 = state.bind_parameter_buffer<float>(2);
        gamma_c1 = 1 * 200.0f;    }

    NV_IDX_DEVICE_INLINE_MEMBER
    int execute(
        const Sample_info_self&  sample_info,
              Sample_output&     sample_output)
    {    
        // retrieve volume & colormap
        const Sparse_volume& volume_01 = state.scene.access<Sparse_volume>(SLOT_VOLUME_1);
        const Sparse_volume& volume_02 = state.scene.access<Sparse_volume>(SLOT_VOLUME_2);

        // set current slot
        const float3 sample_pos = sample_info.sample_position_object_space;

        // get colormap references
        const Colormap cmap_01 = state.scene.access<Colormap>(SLOT_CMAP_1);
        const Colormap cmap_02 = state.scene.access<Colormap>(SLOT_CMAP_2);
        
        // create sampling context
        const auto sampler_01 = volume_01.generate_sampler<float>(field_id);    // channel 0
        const auto sampler_02 = volume_02.generate_sampler<float>(field_id);    // channel 1

        // sample volume and colormap
        float val_01 = sampler_01.fetch_sample(sample_pos);
        float val_02 = sampler_02.fetch_sample(sample_pos);

        // init channel 1 colors
        float4 col_02 = cmap_02.lookup(val_02);
        float scale_c01 = 1.0f;

        if (col_02.w > min_c1_alpha)
        {
            // iterate filter
            float max_c0 = val_01;
            float min_c0 = val_01;

            for (uint xc=0; xc < filter_dim.x; xc++)
            {
                const float tx = xc / ((float)filter_dim.x - 1.0f);
                const float ox = (tx * 2.0f - 1.0f) * filter_offset.x;

                for (uint yc=0; yc < filter_dim.y; yc++)
                {
                    const float ty = yc / ((float)filter_dim.y - 1.0f);
                    const float oy = (ty * 2.0f - 1.0f) * filter_offset.y;

                    for (uint zc=0; zc < filter_dim.z; zc++)
                    {
                        // compute filter offset
                        const float tz = zc / ((float)filter_dim.z - 1.0f);
                        const float oz = (tz * 2.0f - 1.0f) * filter_offset.z;

                        // sample channel 0
                        const float3 off_vec = make_float3(ox, oy, oz);
                        const float sample = sampler_01.fetch_sample(sample_pos + off_vec);

                        // get maximum
                        max_c0 = max(sample, max_c0);
                        min_c0 = min(sample, min_c0);
                    }
                }
            }

            // assign scaling factor
            scale_c01 = (max_c0 - min_c0) * gamma_c1 * max_c1_scale;
        }

        // apply gamma correction to each channel
        // note: changes value range, colormap range adaption required
        val_01 = powf(val_01, (1.0f / gamma_c0));
        //val_02 = powf(val_02, (1.0f / gamma_c1));

        // lookup color
        const float4 col_01 = cmap_01.lookup(val_01);
        col_02 = cmap_02.lookup(val_02);
        
        // init output color
        float4 output_color = (col_01.w > col_02.w) ? col_01 : col_02;

        if (col_01.w > col_02.w)
        {
            // show channel 0
            output_color = col_01;
        }
        else
        {
            // show channel 1
            output_color = clamp(col_02 * scale_c01, 0.0f, 1.0f);
            output_color.w = max(output_color.w, col_01.w);
        }

        // additional blending operations (overwrite previous result)

        // a) add colors
        //output_color = (col_01 + col_02) / 2.0f;
        
        // b) weighted blending
        //output_color = (col_01 * col_01.w + col_02*col_02.w) / 1.0f;

        // set final color
        sample_output.set_color(output_color);

        return NV_IDX_PROG_OK;
    }
};
