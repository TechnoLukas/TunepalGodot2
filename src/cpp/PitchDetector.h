/*
 *  PitchDetector.h
 *  iTunePal
 *
 *  Created by Bryan Duggan on 06/03/2010.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#pragma once

#include <vector>

using namespace std;


vector<int> calculatePeaks(float * data, int border, int howFar, float thresholdNormal);
float mikelsFrequency(float * fftMag, int size, int sampleRate, int frameSize);



