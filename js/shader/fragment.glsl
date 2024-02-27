uniform float time;
uniform float progress;
uniform sampler2D texture1;
uniform vec4 resolution;
varying vec2 vUv;
varying vec3 vPosition;
float PI = 3.141592653589793238;

float rand(float n){return fract(sin(n) * 43758.5453123);}

float rand(vec2 n) { 
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(float p){
	float fl = floor(p);
  float fc = fract(p);
	return mix(rand(fl), rand(fl + 1.0), fc);
}
	
float noise(vec2 n) {
	const vec2 d = vec2(0.0, 1.0);
  vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
	return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

void main()	{
	// vec2 newUV = (vUv - vec2(0.5))*resolution.zw + vec2(0.5);

	// get a checkerboard grid 10 x 10
	float x = floor(vUv.x * 10.0);
	float y = floor(vUv.y * 10.0);

    // use noise to paint each grid cell with a random shade intensity
	float newNoise = noise(vec2(x, y));


	float width = 0.5;
	float newProgress = progress;
	// map that ranges so gradient starts transparent then grows with progress
	newProgress = map(newProgress, 0., 1., -width, 1.);
	// use the progress to animate the black gradient along the x axis
	newProgress = smoothstep(newProgress, newProgress + width, vUv.x);

	// mix the noise with the gradient to create the final pattern 
	float patternProgress = 2. * newProgress - newNoise;


	gl_FragColor = vec4(vec3(patternProgress), 1.);
}