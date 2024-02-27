 // Varyings
varying vec2 vUv;
varying vec2 vLayoutUv;

// Uniforms: Common
uniform float uOpacity;
uniform float uThreshold;
uniform float uAlphaTest;
uniform vec3 uColor;
uniform sampler2D uMap;

// Uniforms: Strokes
uniform vec3 uStrokeColor;
uniform float uStrokeOutsetWidth;
uniform float uStrokeInsetWidth;
uniform float uProgress;
uniform float time;

// Utils: Median
float median(float r, float g, float b) {
    return max(min(r, g), min(max(r, g), b));
}

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

void main() {
    // Common
    // Texture sample
    vec3 s = texture2D(uMap, vUv).rgb;

    // Signed distance
    float sigDist = median(s.r, s.g, s.b) - 0.5;

    float afwidth = 1.4142135623730951 / 2.0;

    #ifdef IS_SMALL
        float alpha = smoothstep(uThreshold - afwidth, uThreshold + afwidth, sigDist);
    #else
        float alpha = clamp(sigDist / fwidth(sigDist) + 0.5, 0.0, 1.0);
    #endif

    // Strokes
    // Outset
    float sigDistOutset = sigDist + uStrokeOutsetWidth * 0.5;

    // Inset
    float sigDistInset = sigDist - uStrokeInsetWidth * 0.5;

    #ifdef IS_SMALL
        float outset = smoothstep(uThreshold - afwidth, uThreshold + afwidth, sigDistOutset);
        float inset = 1.0 - smoothstep(uThreshold - afwidth, uThreshold + afwidth, sigDistInset);
    #else
        float outset = clamp(sigDistOutset / fwidth(sigDistOutset) + 0.5, 0.0, 1.0);
        float inset = 1.0 - clamp(sigDistInset / fwidth(sigDistInset) + 0.5, 0.0, 1.0);
    #endif

    // Border
    float border = outset * inset;

    // Alpha Test
    if (alpha < uAlphaTest) discard;

    // Output: Common
    vec4 filledFragColor = vec4(uColor, uOpacity * alpha);

    // Output: Strokes
    vec4 strokedFragColor = vec4(uStrokeColor, uOpacity * border);


    // CHECKERBOARD TEXT
    vec4 blackText = vec4(0.,0.,0.,1.);
    vec4 blackStrokeText = vec4(blackText * uOpacity * border);
    vec4 whiteText = vec4(1.,1.,1.,1.); // l4
    vec4 whiteStrokeText = vec4(whiteText * uOpacity * border); //l2
    vec4 greyStrokeText = vec4(1.,1.,1., border * .5); //l1
    vec4 pinkColor = vec4(0.834,0.066,.780,1.); // l3
    vec4 pinkStrokeColor = vec4(pinkColor * uOpacity * border);


    // Output: Checkerboard
    	// get a checkerboard grid 10 x 10
	float x = floor(vLayoutUv.x * 10.0);
	float y = floor(vLayoutUv.y * 10.0);

    // use noise to paint each grid cell with a random shade intensity
	float newNoise = noise(vec2(x, y));


	float width = 0.5;
	float newProgress = uProgress;
	// map that ranges so gradient starts transparent then grows with progress
	newProgress = map(newProgress, 0., 1., -width, 1.);
	// use the progress to animate the black gradient along the x axis
	newProgress = smoothstep(newProgress, newProgress + width, vLayoutUv.x);

	// mix the noise with the gradient to create the final pattern 
	float patternProgress = 2. * newProgress - newNoise;
    patternProgress = clamp(patternProgress, 0., 1.);



    //gl_FragColor = greyStrokeText;
    // gl_FragColor = pinkColor;

    // gradient noise pattern
    // gl_FragColor = vec4(vec3(patternProgress), 1.);

    // outline noise pattern
    gl_FragColor = mix(vec4(0.), whiteStrokeText, 1. -patternProgress); // animate in
    //gl_FragColor = mix(vec4(0.), whiteStrokeText, patternProgress); // animate out
}