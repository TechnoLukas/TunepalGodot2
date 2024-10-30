#include <string>
#include <jni.h>
#include <stdio.h>
#include "utils.h"
#include "transcriber.h"


using namespace std;

int g_fundamental = 3;

extern "C" {         
    //jint Java_org_tunepal_Transcriber_PowerSpectrum( JNIEnv* env,jobject thiz, jint frameSize, jfloatArray in, jfloatArray out)
    jstring Java_org_tunepal_Transcriber_fastTranscribe( JNIEnv* env,jobject thiz, jfloatArray in, jint fundamental, jint midi)
    {
		
		
        float f = 0.0f;
        bool b = false;
        jfloat *signal = env->GetFloatArrayElements(in, 0);
		g_fundamental = fundamental;		
        Transcriber transcriber;
        transcriber.setSignal(signal);
		//return env->NewStringUTF("HELLO!");
        string transcription = transcriber.transcribe(& f, & b, midi);
	
        return env->NewStringUTF(transcription.c_str());
		
     }
}



extern "C" {
    jstring Java_org_tunepal_Tune_createMidiFile(JNIEnv* env,jobject thiz, jstring pnotation, jstring pABCFileName, jstring pMidiFileName, jint pspeed, jint ptranspose, jint pmelody, jint pchords)
    {
        const char * notation = env->GetStringUTFChars(pnotation, NULL);
        const char * abcFileName = env->GetStringUTFChars(pABCFileName, NULL);
        const char * midiFileName = env->GetStringUTFChars(pMidiFileName, NULL);

        char * result = createMidiFile(notation, abcFileName, midiFileName, pspeed, ptranspose, pmelody, pchords);

        env->ReleaseStringUTFChars(pnotation, notation);
        env->ReleaseStringUTFChars(pABCFileName, abcFileName);
        env->ReleaseStringUTFChars(pMidiFileName, midiFileName);

        return env->NewStringUTF(result);
    }
}

