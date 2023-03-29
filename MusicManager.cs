using UnityEngine;

public class MusicManager : MonoBehaviour
{
    public AudioSource source;
    public AudioClip levelaudio;
    public float activity = 0f;
    public float[] exportedSpectrum;

    private void Awake()
    {
        startMusic();
    }

    public void startMusic()
    {
        source.clip = levelaudio;
        source.Play();
    }

    void Update()
    {
        if (source.isPlaying)
        {
            float[] spectrum = new float[256];
            AudioListener.GetSpectrumData(spectrum, 0, FFTWindow.Rectangular);
            activity = 0;
            for (int i = 1; i < spectrum.Length - 1; i++)
            {
                activity += spectrum[i];
                #if UNITY_EDITOR
                Debug.DrawLine(new Vector3(Mathf.Log(i - 1), spectrum[i - 1] - 10, 1) * 50, new Vector3(Mathf.Log(i), spectrum[i] - 10, 1) * 50, Color.green); //I recommend looking at this, its really cool 0-0
                #endif
            }
            exportedSpectrum = spectrum;
        }
    }
}