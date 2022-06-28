/******************************************************************************
 * Copyright 2020 NVIDIA Corporation. All rights reserved.
 *****************************************************************************/

// # XAC Kernel:
// ** Smoothed Surface Grid Rendering **

// # Summary: 
// Show global gridlines intersecting the surface and sample a predefined volume.

NV_IDX_XAC_VERSION_1_0

#define SLOT_VOLUME     1

using namespace nv::index;
using namespace nv::index::xac;

struct data_buffer { float4 input_buffer; };

class Surface_sample_program 
{
    NV_IDX_SURFACE_SAMPLE_PROGRAM
    
    // color the surface by volume
    const bool color_by_volume      = true;
    
    // define axis colors
    const float gca                 = 0.9f;
    const float gcb                 = 0.4f;
    const float grid_alpha          = 0.2f;
    const float fixed_alpha         = 0.8f;

    // grid axis colors
    const float4 grid_color_x       = make_float4(gca, gcb, gcb, grid_alpha);
    const float4 grid_color_y       = make_float4(gcb, gca, gcb, grid_alpha);
    const float4 grid_color_z       = make_float4(gcb, gcb, gca, grid_alpha);

    const float4 outside_color      = make_float4(0.3f);
    
    // grid parameters
    const float3 grid_res           = transform_vector(state.scene.get_world_to_scene_transform_inverse(),make_float3(2000,200,200));
    const float grid_linewidth      = 5.0f;
    float glow_scale                = 2.0f;
    float grid_exp                  = 3.0f;

    const data_buffer*  m_array_buffer;

public:
    NV_IDX_DEVICE_INLINE_MEMBER
    void initialize() 
    {
        // bind a user parameter buffer
        m_array_buffer = state.bind_parameter_buffer<data_buffer>(0);
    }

    NV_IDX_DEVICE_INLINE_MEMBER
    int execute(
        const   Sample_info_self&  sample_info,     // read-only
                Sample_output&     sample_output)   // write-only
    {
        // Retrieve sampling information
        const float3 scene_position = sample_info.scene_position;

        // Use a fixed volume ID for now (corresponds to first volume in subregion)
        const auto& volume = state.scene.access<Sparse_volume>(SLOT_VOLUME);
        
        // Initiate sample position
        float3 sample_position = make_float3(0.0f);
        float4 output_color = sample_info.sample_color;
        
        // Use convenience function
        const auto& transform_mat = volume.get_scene_to_object_transform();
        sample_position = transform_point(transform_mat, scene_position);

        // No gridline, compute regular color
        if (color_by_volume)
        {
            const float3& box_min = volume.get_volume_bbox_min();
            const float3& box_max = volume.get_volume_bbox_max();
            //const bool is_inside = xaclib::is_inside_bounding_box(box_min, box_max, sample_position);
            
            // Check if volume is valid
            if (state.scene.is_valid_element<Sparse_volume>(SLOT_VOLUME))
            {
                const auto sampler = volume.generate_sampler<float, Volume_filter_mode::TRILINEAR>(0u);
                                                
                // Get the colormap of the current volume
                //const Colormap& colormap = volume.get_colormap();

                // Alternative: use object colormap (height fields and planes only)
                const Colormap& colormap = state.self.get_colormap();

                // Sample the current volume & color map
                const float sample_value = sampler.fetch_sample(sample_position);
                float4 sample_color = colormap.lookup(sample_value);
                sample_color.w = (fixed_alpha > 0) ? fixed_alpha : sample_color.w;

                // Set the output color
                output_color = sample_color;
            }
        }
        else output_color = outside_color;

        // blend grid colors
        float user_input = (-m_array_buffer[0].input_buffer.w * 0.001f);    // [0,1]
        float glwidth = grid_linewidth + user_input * 10.0f;

        output_color = interp_grid_color(output_color, grid_color_x, scene_position.x, grid_res.x, glwidth);
        output_color = interp_grid_color(output_color, grid_color_y, scene_position.y, grid_res.y, glwidth);
        output_color = interp_grid_color(output_color, grid_color_z, scene_position.z, grid_res.z, glwidth);

        // write color to output
        sample_output.set_color(output_color);

        return NV_IDX_PROG_OK;
    }

    NV_IDX_DEVICE_INLINE_MEMBER
    float4 interp_grid_color(const float4& ref_color, const float4& grid_color, float tp, float res, float width)
    {
        // check of reference position is inside line width band
        float hw = width / 2.0f;
        float ts = fmodf(tp + hw, res) / hw;
        float glow_fac = 1.0f;

        // check if interpolation should be applied
        if (grid_exp > 0.0f)
        {
            if (ts <= 2.0f)
            {
                if (ts < 1.0f)
                {
                    // lower half line
                    ts = powf(ts, grid_exp);
                    glow_fac = (glow_scale > 0.0f) ? (ts * glow_scale) : 1.0f;
                    return clamp((1.0f - ts) * ref_color + ts * grid_color * glow_fac, 0.0f, 1.0f);
                }
                else 
                {
                    // upper half line
                    ts = powf(2.0f - ts, grid_exp);
                    glow_fac = (glow_scale > 0.0f) ? (ts * glow_scale) : 1.0f;
                    return clamp((1.0f - ts) * ref_color + ts * grid_color * glow_fac, 0.0f, 1.0f);
                }
                
            }
            else return ref_color;
        }
        else return (ts <= 2.0f) ? grid_color : ref_color;
    }
}; // class Surface_sample_program
