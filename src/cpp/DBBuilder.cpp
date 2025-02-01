#include <string>
#include <curl/curl.h>
#include <sstream>
#include <iostream>

// Callback function to handle received data

// https://stackoverflow.com/questions/50013204/jsoncpp-to-parse-from-url

static size_t WriteCallback(void* contents, size_t size, size_t nmemb, void* userp) {
    ((std::string*)userp)->append((char*)contents, size * nmemb);
    return size * nmemb;
}

std::string FetchJSONFromURL(const std::string& url) {
    CURL* curl = curl_easy_init();
    std::string readBuffer;
    
    if(curl) {
        CURLcode res;
        
        // Set URL
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        
        // Set callback function
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &readBuffer);
        
        // Perform request
        res = curl_easy_perform(curl);
        
        // Check for errors
        if(res != CURLE_OK) {
            std::cerr << "curl_easy_perform() failed: " << 
                        curl_easy_strerror(res) << std::endl;
            readBuffer.clear();
        }
        
        // Cleanup
        curl_easy_cleanup(curl);
    }
    
    return readBuffer;
}