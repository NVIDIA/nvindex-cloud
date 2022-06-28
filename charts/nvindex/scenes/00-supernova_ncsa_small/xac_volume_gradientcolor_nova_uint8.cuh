/******************************************************************************
 * Copyright 2020 NVIDIA Corporation. All rights reserved.
 *****************************************************************************/

// ** Volume Gradient Colormapping **

// # Summary:
// Compute the volume gradient and map to the given colormap.

NV_IDX_XAC_VERSION_1_0

struct data_buffer
{   
    float4 input_buffer;
};

using namespace nv::index;
using namespace nv::index::xac;

class Volume_sample_program
{
    NV_IDX_VOLUME_SAMPLE_PROGRAM

    const float grad_max        = 40.0f;    // maximum gradient scale
    const float min_alpha       = 0.001f;   // min alpha to trigger gradient computation
    const float dh              = 2.0f;     // finite-differencing stepsize
    const float screen_gamma    = 0.55f;
    const float grad_fac        = 0.5f;
    
    const float4 nova_color     = make_float4(1.0f, 0.4f , 0.0f, 1.0f);
    const float3 nova_center    = make_float3(316.5f);
    const float nova_max_dist   = 8.0f;
    const float nova_falloff_exp = 1.75f;
    
    const bool use_user_input   = false;

    // Gradient Color method:
    // 0: use z gradient only
    // 1: use x,y gradient only
    // 2: use gradient magnitude
    // 3: darken sample color by magnitude
    const int color_method      = 3;

    // Use gradient to set transparency
    const bool use_grad_alpha   = 1;
    
    const Colormap colormap = state.self.get_colormap();
    const data_buffer*  m_array_buffer;

public:
    NV_IDX_DEVICE_INLINE_MEMBER
    void initialize()
    {
        m_array_buffer = state.bind_parameter_buffer<data_buffer>(0);
    }

    NV_IDX_DEVICE_INLINE_MEMBER
    int execute(
        const Sample_info_self&         sample_info,
              Sample_output&            sample_output)
    {
        const float3& sample_position = sample_info.sample_position_object_space;
        const float3& scene_position = sample_info.scene_position;
        
        // highlight core region
        const float dist = length(nova_center - scene_position);
        if (dist < nova_max_dist)
        {
            float nd = 1.0f - (dist / nova_max_dist);
            nd = powf(nd, nova_falloff_exp);
            
            float4 color;
            color = (1.0f - nd) * make_float4(1.0f) + nd * nova_color;
            color.w = nd;
            sample_output.set_color(color);
            
            return NV_IDX_PROG_OK;
        }
        
        // sample volume, local gradient and color:
        // old: const float  volume_sample = state.self.sample<float>(sample_position);
        // new:
        // get reference to the sparse volume & its colormap
        const Sparse_volume& volume = state.self;
        const Colormap colormap = volume.get_colormap();

        const uint field_index = 0u;
        const auto& sample_context = sample_info.sample_context;
        const auto sampler = volume.generate_sampler<float>(
                                                        field_index,
                                                        sample_context);
        const float volume_sample = sampler.fetch_sample(sample_position);

        const float4 sample_color  = colormap.lookup(volume_sample);

        // check if sample can be skipped
        if (sample_color.w < min_alpha) return NV_IDX_PROG_DISCARD_SAMPLE;

        // approximate the the volume gradient based on finite-differences
        const float3 vol_grad = xaclib::volume_gradient(volume, sample_position, dh);
 
        // scale gradient by user input
        const float user_input = (-m_array_buffer[0].input_buffer.w * 0.001f);    // [0,1]
        
        float grad_scale = grad_fac * grad_max; 
        if (use_user_input) grad_scale = user_input * grad_max; 
        
        float4 output_color;
        if (color_method == 0)
        {
            // color by height gradient
            output_color  = colormap.lookup(vol_grad.z * grad_scale);
        }
        else if (color_method == 1)
        {
            // color by x,y gradient
            const float vs_xy_mag = sqrt(pow(vol_grad.x,2.0f) * pow(vol_grad.y,2.0f));
            output_color  = colormap.lookup(vs_xy_mag * grad_scale);
        }
        else if (color_method == 2)
        {
            // color by gradient magnitude
            const float grad_mag = length(vol_grad);
            output_color  = colormap.lookup(grad_mag * grad_scale);
        }
        else
        {
            // shade color by gradient magnitude
            const float grad_mag = length(vol_grad);
            output_color  = clamp(sample_color * (grad_mag * grad_scale),0.0f,1.0f);
        }

        if (!use_grad_alpha) output_color.w = sample_color.w;
        
        // apply gamma correction
        sample_output.set_color(nv::index::xaclib::gamma_correct(output_color, screen_gamma));

        return NV_IDX_PROG_OK;
    }
};
