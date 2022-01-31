//Ray marching shader
//Based on : https://www.youtube.com/watch?v=PGtv-dBi2wE

uniform float uTime;
uniform vec2 uPlaneRes;
uniform vec2 uCanvasRes;
uniform vec2 uMouse;
uniform float uPixelRatio;

varying vec2 vUv;

#define MAX_STEPS 100 //integer
#define MAX_DIST 100.0 //float
#define SURF_DIST .01


//our 3d scene that is used to compute distanceces
float GetDist(vec3 p) {
    vec4 s = vec4(0.0, 1.0, 6.0, 1.0); //defining sphere -> (pos.x, pos.y, pos.z, radius)
    float sphereDist = length(p - s.xyz) - s.w;
    float planeDist = p.y; //The plane (surface) is on the floor so the distance is just the height of camera
    float d = min(sphereDist, planeDist);
    return d;
}

float RayMarch (vec3 ro, vec3 rd){
    float dO = 0.0; //How far away we are from the ray origin

    for(int i = 0; i<MAX_STEPS; i++){
        vec3 p = ro + rd * dO; // It's the new position of the raymarched point casted from the ray origin along the ray
        float dS = GetDist(p);//distance to the closest point in the scene , (from this point we start next loop because this distance is added to dO)
        dO += dS;
        if(dO > MAX_DIST || dS < SURF_DIST) break; // Checks if we hit something or went past by the object and MAX distance
    }

    return dO;
}

//Samples the points around point p to get the line that is perpendicular to normal vector
vec3 GetNormal( vec3 p ){
    float d = GetDist(p);
    vec2 e = vec2( 0.01, 0.0);
    vec3 n = d- vec3(GetDist(p - e.xyy), GetDist(p - e.yxy), GetDist(p - e.yyx));
    return normalize(n);
}

float GetLight (vec3 p) {
    //To compute the light power, we need the light vector (direction of the light) and the normal vector in the given point p (also the direction)

    vec3 lightPos = vec3(0.0, 5.0, 6.0); //Define the position of light
    lightPos.xz += vec2(sin(uTime), cos(uTime)) * 2.2;
    vec3 l = normalize(lightPos - p);
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l), 0.0, 1.0); //returns 1.0 when the vectors have the same direction and 0.0 when totally opposite using dot product and clamp

    //Implement casting shadows - rayMarch from point to the light, if the 
    //distance is less than the distance between points it means something was standing on their way
    //We add n * SURF_DIST * 2.0 otherwise the RayMarch loop breaks right after it starts because previously we have found the surface nearby
    float d = RayMarch(p + n * SURF_DIST * 2.0, l); 
    if(d<length(lightPos - p)) dif *= .1; //Shadow is 10% of an actual light
    return dif;
}

void main()
{
    vec2 uv = vUv;
    uv -= 0.5;
    vec3 col = vec3(0.0);

    vec3 ro = vec3(0.0, 1.0, 0.0); //ray origin (camera position)
    vec3 rd = normalize(vec3(uv.x, uv.y, 1.0));

    float d = RayMarch(ro, rd); //The distance to the closest point that interesects with casted ray

    //We can't output just the distance becuase it is already bigger than 1.0 at the beginning (the plane is 1.0 above ground)
    //We need to calculate the light power (between 0.0, 1.0) for each pixel:
    vec3 p = ro + rd *d;
    float dif = GetLight(p); //diffused lighting
    col = vec3(dif);

    gl_FragColor = vec4(col, 1.0);
}