/******************************************************************************
 * Copyright 2020 NVIDIA Corporation. All rights reserved.
 *****************************************************************************/

// # RTC Kernel:
// ** Sparse Volume Depth Enhancement **

// # Summary: 
// Apply a local front-to-back averaging along a predefined ray segment to darken samples in low alpha regions.

#define NV_IDX_XAC_USE_RELAXED_SVOL_BOUNDARY_CHECK

NV_IDX_XAC_VERSION_1_0

using namespace nv::index::xac;
using namespace nv::index::xaclib;

class Volume_sample_program
{
    NV_IDX_VOLUME_SAMPLE_PROGRAM

    private:
    
    // additional depth samples
    const int max_ray_steps         = 8;                    // [GUI] number of additional samples

    // shading parameters [GUI / scene]
    const float3 spec_color         = make_float3(1.0f);    // specular color

    const float specular            = 0.2f;                 // specular factor (phong)
    const float shininess           = 50.0f;                // shininess parameter (phong)
    const float amb_fac             = 0.2f;                 // ambient factor

    const float shade_min_alpha     = 0.05f;                 // [GUI] min alpha value for shading
    const float min_alpha           = 0.005f;               // min alpha for sampling (improves performance)
    const float min_grad_length     = 0.001f;

    const float screen_gamma        = 0.8f;                 // [GUI] gamma correction parameter

    // get constant scene parameters
    const float3 cam_up             = state.scene.camera.get_up();
    const float3 cam_right          = state.scene.camera.get_right();

    const float rh                  = 1.0f;
    const float dh                  = 0.5f;

    const uint field_index          = 0u;
    const float param_value         = 0.0f;

    public:
    NV_IDX_DEVICE_INLINE_MEMBER
    void initialize() 
    {}

    NV_IDX_DEVICE_INLINE_MEMBER
    int execute(
        const Sample_info_self&  sample_info,
              Sample_output&     sample_output)
    {
        // retrieve ray intersection properties
        const float3& sample_position = sample_info.sample_position_object_space;
        const float3& ray_dir = sample_info.ray_direction;

        // get sparse volume reference
        const auto& sparse_volume = state.self;
        const auto& sample_context = sample_info.sample_context;

        const auto sampler = sparse_volume.generate_sampler<float>(
                                                         field_index,
                                                         sample_context);

        const auto grad_sampler = sparse_volume.generate_sampler<float, Volume_filter_mode::TRILINEAR>(
                                                         field_index,
                                                         sample_context);

        // get the associated colormap
        const Colormap colormap = sparse_volume.get_colormap();

        // construc a light position based on the camera position;
        const float3 light_dir = normalize((1.0f-param_value) * cam_up + param_value * cam_right);
        
        // sample volume along the ray
        const float3 p0 = sample_position;
        const float3 p1 = sample_position + (ray_dir * rh);

        const float vs_p0 = sampler.fetch_sample(p0);
        const float vs_p1 = sampler.fetch_sample(p1);
        
        const float vs_min = min(vs_p0, vs_p1);
        const float vs_max = max(vs_p0, vs_p1);

        // first sample
        const float4 sample_color  = colormap.lookup(vs_p0);
        sample_output.set_color(sample_color);

        // stop computation if opacity is below threshold (improves performance)
        if (sample_color.w < min_alpha)
        {
            sample_output.set_color(sample_color);
            return NV_IDX_PROG_OK;
        }

        // check the number of steps to take along the ray
        if (max_ray_steps > 1)
        {
            // init result color
            float4 acc_color = make_float4(0.0f);

            // iterate steps
            for (int ahc=0; ahc < max_ray_steps; ahc++)
            {
                // get step size
                const float rt = float(ahc) / float(max_ray_steps);
                const float3 pi = (1.0f-rt) * p0 + rt * p1;

                // sample current position
                const float vs_pi = sampler.fetch_sample(pi);
                const float4 cur_col  = colormap.lookup(vs_pi);

                // front-to-back blending
                const float omda = (1.0f - acc_color.w);

                acc_color.x += omda * cur_col.x * cur_col.w;
                acc_color.y += omda * cur_col.y * cur_col.w;
                acc_color.z += omda * cur_col.z * cur_col.w;
                acc_color.w += omda * cur_col.w; 
            }

            // assign result color
            sample_output.set_color(acc_color);
        }

        // check if local shading has to be applied
        if (sample_color.w > shade_min_alpha)
        {
            // get the volume gradient
            // compute volume gradient (use trilinear filter for gradients)
            const float3 vs_grad = volume_gradient<Volume_filter_mode::TRILINEAR>(
                        sparse_volume,
                        sample_context,
                        sample_position,
                        field_index,
                        dh);

            // check gradient length
            if (length(vs_grad) < min_grad_length) return NV_IDX_PROG_OK;

            // get isosurface normal
            const float3 iso_normal = -normalize(vs_grad);
            
            // set ambient & diffuse color
            const float3 ambient_color = make_float3(sample_color);
            const float3 diffuse_color = make_float3(sample_color);
            
            // init shading parameters
            const float lambertian = fabsf(dot(light_dir,iso_normal));
            float spec_fac = specular;

            // check normal direction (two-sided shading)
            if(lambertian > 0.0f) 
            {
                // this is blinn phong
                const float3 half_dir = normalize(light_dir + ray_dir);
                const float spec_angle = fabsf(dot(half_dir, iso_normal));

                spec_fac = powf(spec_angle, shininess);
            }
            
            // compute final shaded color (RGB)        
            float4 color_linear = make_float4(ambient_color * amb_fac + lambertian * diffuse_color + spec_fac * spec_color);
            
            // apply gamma correction
            color_linear = gamma_correct(color_linear,screen_gamma);
            color_linear.w = sample_color.w;
            color_linear = clamp(color_linear, 0.0f, 1.0f);

            // clamp result color
            sample_output.set_color(color_linear);
        }

        return NV_IDX_PROG_OK;
    }
}; // class Volume_sample_program
