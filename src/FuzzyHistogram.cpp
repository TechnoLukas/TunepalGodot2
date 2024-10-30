/*
 *  FuzzyHistogram.cpp
 *  recording
 *
 *  Created by Bryan Duggan on 17/01/2010.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#include "FuzzyHistogram.h"

#include <stdio.h>
#include <vector>
#include <algorithm>

using namespace std;

bool compareLengths(Candidate d1, Candidate d2)
{
	return d1.count > d2.count;
}


float FuzzyHistogram::calculatePeek(float * data, int count, float fuzz, float atLeast)
{
	this->data = data;
	this->count = count;
	float duration = 0.0f;
	
	vector<Candidate> candidateLengths;
	
	for (int i = 0 ; i < count ; i ++)
	{
		// See if we already have an element in the histogram of this value
		bool found = false;
		for (int j = 0 ; j < candidateLengths.size(); j ++)
		{
			float upper, lower;
			Candidate current = candidateLengths[j];
			upper = current.value * ( 1.0f + fuzz);
			lower = current.value * ( 1.0f - fuzz);
			if ((data[i] >= lower) && (data[i] <= upper))
			{
				found = true;
				//current.value = (current.value + data[i]) / 2.0f;
				current.count ++;
				current.value = ((current.value * (float) current.count) + data[i]) / (float) ++ current.count;
				candidateLengths[j] = current;
				break;
			}
		}
		if (!found)
		{
			Candidate newCandidate;
			newCandidate.value = data[i];
			newCandidate.count = 1;           
			candidateLengths.push_back(newCandidate);
		}
	}
	printf("Histogram:\n");
	sort(candidateLengths.begin(), candidateLengths.end(), compareLengths);
	for (int i= 0 ; i < candidateLengths.size(); i ++)
	{
		Candidate candidate = candidateLengths[i];
		printf("%f - %d\n", candidate.value, candidate.count);

	}
	
	// It must be at least the alLeast value
	int i = 0;
	Candidate candidate;
	do
	{
		candidate = candidateLengths[i];
		duration = candidate.value;
		i ++;
	}
	while ((candidate.value < atLeast) && (i < candidateLengths.size()));
	// Have we totally screwed up the quantisation? If so, return the minimum note length
	if (i == candidateLengths.size())
	{
		return atLeast;
	}
	
	return duration;
}

Candidate::Candidate()
{
	value = 0.0f;
	count = 0;
}

