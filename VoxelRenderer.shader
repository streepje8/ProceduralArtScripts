//This epic shader was made with the help of this epic video: https://youtu.be/YP0_aA_wKfU 
//The technique is super cool
Shader "Wezzel/VoxelRenderer"
{
    Properties
    {
        _VoxelSize("Voxel Size", Range(0.0,5.0)) = 1
        _ColorTexture("Color Atlas", 2D) = "white" {}
        [Normal]_NormalTexture("Normal Atlas", 2D) = "white" {}
        _ImagesPerRow("Images per row", Int) = 10
        _ImagesPerColumn("Images per column", Int) = 10
        [HDR]_GlowColor("GLOW COLOR", Color) = (1,1,1,1)
        _GlowAmount("GLow Amount", Float) = 0
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma target 5.0
            
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct voxel
            {
                int type;
                float3 position;
                float activity;
            };
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                uint voxelID : SV_VertexID;
            };

            struct v2g
            {
                float2 extraData : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            struct g2f
            {
                voxel voxeldata : voxel;
                float3 normal : Normal0;
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            StructuredBuffer<voxel> _VoxelData;

            v2g vert (appdata v)
            {
                v2g o;
                voxel voxel = _VoxelData[v.voxelID];
                float3 posXYZ = voxel.position;
                o.vertex = float4(posXYZ.x,posXYZ.y,posXYZ.z,1);
                o.extraData = float2(v.voxelID,voxel.type % 10u);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float _VoxelSize;

            [maxvertexcount(24)]
            void geom(point v2g p[1], inout TriangleStream<g2f> triStream)
            {
                float2 uvs[4];
                
                uvs[0] = float2(0.0f,0.0f);
                uvs[1] = float2(0.0f,1.0f);
                uvs[2] = float2(1.0f,0.0f);
                uvs[3] = float2(1.0f,1.0f);

                float3 normals[6];

                normals[0] = float3(0,0,-1);
                normals[1] = float3(1,0,0);
                normals[2] = float3(-1,0,0);
                normals[3] = float3(0,0,1);
                normals[4] = float3(0,1,0);
                normals[5] = float3(0,-1,0);

                float4 v[24];
                v2g vgg = p[0];
                float4 position = vgg.vertex;
                
                //Front face
                v[0] = position + float4(-_VoxelSize,-_VoxelSize,-_VoxelSize,0);
                v[1] = position + float4(-_VoxelSize,_VoxelSize,-_VoxelSize,0);
                v[2] = position + float4(_VoxelSize,-_VoxelSize,-_VoxelSize,0);
                v[3] = position + float4(_VoxelSize,_VoxelSize,-_VoxelSize,0);

                //Left face
                v[4] = position + float4(_VoxelSize,-_VoxelSize,-_VoxelSize,0);
                v[5] = position + float4(_VoxelSize,_VoxelSize,-_VoxelSize,0);
                v[6] = position + float4(_VoxelSize,-_VoxelSize,_VoxelSize,0);
                v[7] = position + float4(_VoxelSize,_VoxelSize,_VoxelSize,0);

                //Right face
                v[8] = position + float4(-_VoxelSize,-_VoxelSize,_VoxelSize,0);
                v[9] = position + float4(-_VoxelSize,_VoxelSize,_VoxelSize,0);
                v[10] = position + float4(-_VoxelSize,-_VoxelSize,-_VoxelSize,0);
                v[11] = position + float4(-_VoxelSize,_VoxelSize,-_VoxelSize,0);

                //Back face
                v[12] = position + float4(_VoxelSize,-_VoxelSize,_VoxelSize,0);
                v[13] = position + float4(_VoxelSize,_VoxelSize,_VoxelSize,0);
                v[14] = position + float4(-_VoxelSize,-_VoxelSize,_VoxelSize,0);
                v[15] = position + float4(-_VoxelSize,_VoxelSize,_VoxelSize,0);

                //Top face
                v[16] = position + float4(-_VoxelSize,_VoxelSize,-_VoxelSize,0);
                v[17] = position + float4(-_VoxelSize,_VoxelSize,_VoxelSize,0);
                v[18] = position + float4(_VoxelSize,_VoxelSize,-_VoxelSize,0);
                v[19] = position + float4(_VoxelSize,_VoxelSize,_VoxelSize,0);

                //Bottom face
                v[20] = position + float4(-_VoxelSize,-_VoxelSize,_VoxelSize,0);
                v[21] = position + float4(-_VoxelSize,-_VoxelSize,-_VoxelSize,0);
                v[22] = position + float4(_VoxelSize,-_VoxelSize,_VoxelSize,0);
                v[23] = position + float4(_VoxelSize,-_VoxelSize,-_VoxelSize,0);

                g2f output;

                int vidx = 0;

                for(int f = 0; f < 6; f++) //For each face
                {
                    for(int fv = 0; fv < 4; fv++) //For each face vertex
                    {
                        output.vertex = mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld,v[vidx]));
                        output.uv = uvs[fv];
                        output.normal = normals[f];
                        output.voxeldata = _VoxelData[p[0].extraData.x];
                        UNITY_TRANSFER_FOG(output, output.vertex);
                        triStream.Append(output);
                        vidx++;
                    }
                    triStream.RestartStrip();
                }
            }


            sampler2D _ColorTexture;
            sampler2D _NormalTexture;
            float4 _GlowColor;
            float _GlowAmount;
            int _ImagesPerRow;
            int _ImagesPerColumn;

            fixed4 frag (g2f i) : SV_Target
            {
                voxel v = i.voxeldata;
                float type = i.voxeldata.type;
                float x = type % _ImagesPerRow;
                float y = (_ImagesPerRow - 1) - floor(type / _ImagesPerRow);
                float xUVSize = (1.0f/(float)_ImagesPerRow);
                float yUVSize = (1.0f/(float)_ImagesPerColumn);
                float2 textureUVStart = float2(x * xUVSize, y * yUVSize);
                float2 uv = textureUVStart + i.uv * float2(xUVSize,yUVSize) * 0.9;
                fixed4 col = tex2D(_ColorTexture,uv);
                col *= (dot((tex2D(_NormalTexture,uv).xyz * 2 - 1).xzy,_WorldSpaceLightPos0) + 1) * 0.5;
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col + (col * _GlowColor * _GlowAmount);
            }
            ENDCG
        }
    }
}
