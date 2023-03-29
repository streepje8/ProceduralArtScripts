using System.Runtime.InteropServices;
using UnityEngine;

struct Voxel
{
    public int type;
    public Vector3 position;
    public float activity;
}

public class VoxelFactory : MonoBehaviour
{
    [Header("Settings")]
    public int cubeCount = 10;
    public float stepsPerSecond = 5;
    public float glowModifier = 1;
    public Transform goal;
    public MusicManager manager;
    
    [Header("Rendering")]
    public Shader voxelRenderer;

    [Header("Processing")] 
    public ComputeShader voxelProcessor;
    
	
    private ComputeBuffer voxelBuffer;
    private int kernelIndex = 0;
    public Material voxelMaterial;
    public int cellSize = 1;
    private bool voxelsUpdated = false;
    private float glowAmountFloat = 0f;

    private Camera cam;
    private void Awake()
    {
        //Setup shaders
        kernelIndex = voxelProcessor.FindKernel("CSMain");
        if(voxelMaterial == null) voxelMaterial = new Material(voxelRenderer);
        
        //Allocate cubes
        CreateVoxels(cubeCount);

        cam = Camera.main;
    }


    private float timer = 0f;
    private void Update()
    {
        timer += Time.deltaTime;
        if (timer > 1 / stepsPerSecond)
        {
            UpdateVoxels();
            timer = 0;
        }
        glowAmountFloat = Mathf.Lerp(glowAmountFloat, manager.activity * glowModifier, 60f * Time.deltaTime);
		var transform1 = cam.transform;
		Vector3 dir = new Vector3(Input.mousePosition.x / 30, Input.mousePosition.y / 30, 50f) - transform1.position;
		dir = dir.normalized;
		cam.transform.rotation = Quaternion.Slerp(transform1.rotation,Quaternion.FromToRotation(Vector3.forward,dir),10f*Time.deltaTime);
    }
    
    private void CreateVoxels(int amount)
    {
        Voxel[] voxels = new Voxel[amount];
        for (int i = 0; i < amount; i++)
        {
            voxels[i] = new Voxel();
            voxels[i].position = new Vector3(Random.Range(-1f,1f),Random.Range(-1f,1f),Random.Range(-1f,1f));
        }
        if(voxelBuffer != null) voxelBuffer.Release();
        voxelBuffer = new ComputeBuffer(amount, Marshal.SizeOf<Voxel>());
        voxelBuffer.SetData(voxels);
        voxelProcessor.SetInt("voxelCount", amount);
    }

    private void UpdateVoxels()
    {
        minDistSqr = minDist * minDist;
        voxelsUpdated = true;
        voxelProcessor.SetVector("position", transform.position);
        voxelProcessor.SetFloat("deltaTime", Time.deltaTime);
        voxelProcessor.SetFloat("time", Time.time);
        voxelProcessor.SetBuffer(kernelIndex,"_VoxelData",voxelBuffer); //This line can probebly be put in the create voxels function
        voxelProcessor.SetVector("goalPos",goal.position);
        voxelProcessor.SetFloats("spectrum", manager.exportedSpectrum);
        voxelProcessor.Dispatch(kernelIndex,cubeCount/2,cubeCount/2,1);
    }

    private void OnRenderObject()
    {
        if(!voxelsUpdated)UpdateVoxels();
        voxelMaterial.SetPass(0);
        voxelMaterial.SetBuffer("_VoxelData", voxelBuffer);
        voxelMaterial.SetFloat("_GlowAmount", glowAmountFloat);
        Graphics.DrawProceduralNow(MeshTopology.Points,cubeCount);
    }

    private void OnDestroy()
    {
        voxelBuffer.Release();
    }
}
