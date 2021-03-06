#ifndef NOSIC
#define NOSIC

fixed _Octaves;
float _Frequency;
float _Amplitude;
float3 _Offset;
float _Lacunarity;
float _Persistence;

void PerlinHash3D(float3 gridcell,
	out float4 lowz_hash_0,
	out float4 lowz_hash_1,
	out float4 lowz_hash_2,
	out float4 highz_hash_0,
	out float4 highz_hash_1,
	out float4 highz_hash_2)
{
	const float2 OFFSET = float2(50.0, 161.0);
	const float DOMAIN = 69.0;
	const float3 SOMELARGEFLOATS = float3(635.298681, 682.357502, 668.926525);
	const float3 ZINC = float3(48.500388, 65.294118, 63.934599);
	gridcell.xyz = gridcell.xyz - floor(gridcell.xyz * (1.0 / DOMAIN)) * DOMAIN;
	float3 gridcell_inc1 = step(gridcell, float3(DOMAIN - 1.5, DOMAIN - 1.5, DOMAIN - 1.5)) * (gridcell + 1.0);
	float4 P = float4(gridcell.xy, gridcell_inc1.xy) + OFFSET.xyxy;
	P *= P;
	P = P.xzxz * P.yyww;
	float3 lowz_mod = float3(1.0 / (SOMELARGEFLOATS.xyz + gridcell.zzz * ZINC.xyz));
	float3 highz_mod = float3(1.0 / (SOMELARGEFLOATS.xyz + gridcell_inc1.zzz * ZINC.xyz));
	lowz_hash_0 = frac(P * lowz_mod.xxxx);
	highz_hash_0 = frac(P * highz_mod.xxxx);
	lowz_hash_1 = frac(P * lowz_mod.yyyy);
	highz_hash_1 = frac(P * highz_mod.yyyy);
	lowz_hash_2 = frac(P * lowz_mod.zzzz);
	highz_hash_2 = frac(P * highz_mod.zzzz);
}

float3 EaseCurve_C2(float3 x) { return x * x * x * (x * (x * 6.0 - 15.0) + 10.0); }

float Perlin3D(float3 P)
{
	float3 Pi = floor(P);
	float3 Pf = P - Pi;
	float3 Pf_min1 = Pf - 1.0;

	float4 hashx0, hashy0, hashz0, hashx1, hashy1, hashz1;
	PerlinHash3D(Pi, hashx0, hashy0, hashz0, hashx1, hashy1, hashz1);

	float4 grad_x0 = hashx0 - 0.49999;
	float4 grad_y0 = hashy0 - 0.49999;
	float4 grad_z0 = hashz0 - 0.49999;
	float4 grad_x1 = hashx1 - 0.49999;
	float4 grad_y1 = hashy1 - 0.49999;
	float4 grad_z1 = hashz1 - 0.49999;
	float4 grad_results_0 =
		rsqrt(grad_x0 * grad_x0 + grad_y0 * grad_y0 + grad_z0 * grad_z0)
		* (float2(Pf.x, Pf_min1.x).xyxy * grad_x0
			+ float2(Pf.y, Pf_min1.y).xxyy * grad_y0
			+ Pf.zzzz * grad_z0);
	float4 grad_results_1 =
		rsqrt(grad_x1 * grad_x1 + grad_y1 * grad_y1 + grad_z1 * grad_z1)
		* (float2(Pf.x, Pf_min1.x).xyxy * grad_x1
			+ float2(Pf.y, Pf_min1.y).xxyy * grad_y1
			+ Pf_min1.zzzz * grad_z1);

	float3 blend = EaseCurve_C2(Pf);
	float4 res0 = lerp(grad_results_0, grad_results_1, blend.z);
	float2 res1 = lerp(res0.xy, res0.zw, blend.y);
	float final = lerp(res1.x, res1.y, blend.x);
	final = final / 2;
	//final範圍在-1~1
	return final;
}

float PerlinNormal(float3 p)
{
	float sum = 0;
	float amplitude = _Amplitude;
	float frequency = _Frequency;
	for (int i = 0; i < _Octaves; i++)
	{
		float h = 0;
		h = Perlin3D((p + _Offset) * frequency);
		sum += h*amplitude;
		frequency *= _Lacunarity;
		amplitude *= _Persistence;
	}
	return sum / _Octaves;
}

#endif