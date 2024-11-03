/*
 *  FuzzyHistogram.h
 *  recording
 *
 *  Created by Bryan Duggan on 17/01/2010.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#pragma once

class FuzzyHistogram 
{	
private:
    float * data;
	int count;
public:
	float calculatePeek(float * data, int count, float fuzz, float atLeast);
};


class Candidate
{
public:
	float value;
	int count;
	Candidate();
};