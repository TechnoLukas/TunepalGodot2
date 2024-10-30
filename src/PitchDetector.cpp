/*
 *  PitchDetector.cpp
 *  iTunePal
 *
 *  Created by Bryan Duggan on 06/03/2010.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#include "PitchDetector.h"

#include <iostream>
#include <algorithm>

vector<int> calculatePeaks(float * data, int border, int howFar, float thresholdNormal)
{
	float thresholdValue = 0;
	// First calculate the threshold
	if (thresholdNormal > 0)
	{
		for (int i = 0 ; i < howFar ; i ++)
		{
			if (data[i] > thresholdValue)
			{
				thresholdValue = data[i];
			}
		}
	}        
	
	thresholdValue = thresholdValue * thresholdNormal;        
	vector<int> peaks;
	
	if (howFar >= border)
	{
		for (int i = border ; i < howFar - border ; i ++)
		{
			bool addPeak = true;
			if (data[i] >= thresholdValue)
			{
				for (int j = 0 ; j < border ; j ++)
				{
					if ((data[i] < data[i - j]) || (data[i] < data[i + j]))
					{
						addPeak = false;
						break;
					}                    
				}
			}
			else
			{
				addPeak = false;              
			}
			if (addPeak)
			{
				peaks.push_back(i);
			}
		}
	}
	return peaks;
}


float * g_sortableData;
bool compareByEnergy(int d1, int d2)
{
	return g_sortableData[d1] > g_sortableData[d2];
}


float mikelsFrequency(float * fftMag, int size, int sampleRate, int frameSize)
{
	float frequency = 0;
	
	int pitchPeek = 2;
	vector<int> peeks = calculatePeaks(fftMag, pitchPeek , size, 0);
	// Sort them in order of descending energy
	g_sortableData = fftMag;	
	sort(peeks.begin(), peeks.end(), compareByEnergy);
		
	
	const int numCandidates = 5;
	const int numHarmonics = 10;
	float maxEnergy = 0;
	float maxCandidate = 0;
	
	
	/*
	 cout << "TOP " <<  numCandidates << " PARTIALS" << endl;
	for (int i = 0 ; i < numCandidates ; i ++)
	{
		 int candidate = peeks[i];
		 cout << candidate << "\t" << fftMag[candidate] << endl;
	}
	 */
	float binWidth = (float) sampleRate / (float) frameSize;
	
	for (int i=0 ; i < numCandidates ; i ++)
	{
		int candidate = peeks[i];
		float energy = 0;
		for (int j = 0 ; j < numHarmonics ; j ++)
		{                
			int harmonic = candidate + (j * candidate);
			//float hLow = harmonic - 2;
			//float hHigh = harmonic + 2;
			
			//float hLow = (int) ((float) harmonic * 0.99);
			//float hHigh = (int) ((float) harmonic * 1.01);
			float hLow = (int) ((float) harmonic - 2);
			float hHigh = (int) ((float) harmonic + 2);
			
			float maxLittleBit = -1;
			for (int k = (int) hLow; k <= (int) hHigh ; k ++)
			{
				if (k < size)
				{
					if (fftMag[k] > maxLittleBit)
					{
						maxLittleBit = fftMag[k];
					}
				}
			}
			energy += maxLittleBit;
		}
		
		if (energy > maxEnergy)
		{
			maxEnergy = energy;
			maxCandidate = candidate;
		}
	}
	
	
	frequency = maxCandidate * binWidth;   
	
	return frequency;
}
