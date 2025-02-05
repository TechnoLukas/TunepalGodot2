#include "DBBuilder.h"
#include <curl/curl.h>
#include <fstream>
#include <iostream>

static size_t WriteCallback(void* contents, size_t size, size_t nmemb, std::string* userp) {
    userp->append((char*)contents, size * nmemb);
    return size * nmemb;
}

void DBBuilder::_bind_methods() {
    godot::ClassDB::bind_method(godot::D_METHOD("initialize_database"), &DBBuilder::initialize_database);
    godot::ClassDB::bind_method(godot::D_METHOD("load_from_file", "filename"), &DBBuilder::load_from_file);
    godot::ClassDB::bind_method(godot::D_METHOD("load_from_url"), &DBBuilder::load_from_url);
}

DBBuilder::DBBuilder() : db_connection(nullptr) {}

DBBuilder::~DBBuilder() {
    if (db_connection) {
        sqlite3_close(db_connection);
    }
}

bool DBBuilder::check_table_exists() {
    const char* sql = "SELECT name FROM sqlite_master WHERE type='table' AND name=?";
    sqlite3_stmt* stmt;
    
    int rc = sqlite3_prepare_v2(db_connection, sql, -1, &stmt, nullptr);
    if (rc != SQLITE_OK) {
        return false;
    }
    
    sqlite3_bind_text(stmt, 1, TABLENAME, -1, SQLITE_STATIC);
    
    bool exists = (sqlite3_step(stmt) == SQLITE_ROW);
    sqlite3_finalize(stmt);
    
    return exists;
}

bool DBBuilder::create_table() {
    const char* sql = "CREATE TABLE Tunes ("
        "ID INT NOT NULL, "
        "SETTING INT NOT NULL, "
        "NAME TEXT, "
        "TYPE CHAR(50), "
        "MODE CHAR(10), "
        "METER CHAR(10), "
        "ABC TEXT, "
        "KEY TEXT, "
        "PARSED TINYINT, "
        "PCHIST TEXT, "
        "PARSED2 TINYINT, "
        "PRIMARY KEY (ID, SETTING))";
    
    char* err_msg = nullptr;
    int rc = sqlite3_exec(db_connection, sql, nullptr, nullptr, &err_msg);
    
    if (rc != SQLITE_OK) {
        std::cerr << "SQL error: " << err_msg << std::endl;
        sqlite3_free(err_msg);
        return false;
    }
    
    return true;
}

bool DBBuilder::initialize_database() {
    std::cout << "Attempting to initialize database..." << std::endl;  // Add this
    int rc = sqlite3_open("../assets/data/tunepal.db", &db_connection);
    if (rc) {
        std::cerr << "Can't open database: " << sqlite3_errmsg(db_connection) << std::endl;
        return false;
    }
    std::cout << "Database initialized successfully" << std::endl;  // Add this
    
    sqlite3_exec(db_connection, "PRAGMA journal_mode=WAL", nullptr, nullptr, nullptr);
    sqlite3_exec(db_connection, "BEGIN TRANSACTION", nullptr, nullptr, nullptr);
    
    if (!check_table_exists()) {
        if (!create_table()) {
            return false;
        }
    }
    
    return true;
}

std::string DBBuilder::fetch_json_from_url(const std::string& url) {
    CURL* curl = curl_easy_init();
    std::string response_data;
    
    if (curl) {
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response_data);
        
        CURLcode res = curl_easy_perform(curl);
        if (res != CURLE_OK) {
            std::cerr << "curl_easy_perform() failed: " << curl_easy_strerror(res) << std::endl;
            response_data.clear();
        }
        
        curl_easy_cleanup(curl);
    }
    
    return response_data;
}

std::string DBBuilder::read_file(const std::string& filename) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        throw std::runtime_error("Could not open file: " + filename);
    }
    
    return std::string(
        std::istreambuf_iterator<char>(file),
        std::istreambuf_iterator<char>()
    );
}

void DBBuilder::populate_database(const json& tunes) {
    const char* sql = "INSERT OR REPLACE INTO Tunes VALUES (?,?,?,?,?,?,?,?,?,?,?)";
    sqlite3_stmt* stmt;
    
    int rc = sqlite3_prepare_v2(db_connection, sql, -1, &stmt, nullptr);
    if (rc != SQLITE_OK) {
        throw std::runtime_error("Failed to prepare statement");
    }
    
    for (const auto& tune : tunes) {
        std::string name = tune["name"].get<std::string>();
        std::string type = tune["type"].get<std::string>();
        std::string mode = tune["mode"].get<std::string>();
        std::string meter = tune["meter"].get<std::string>();
        std::string abc = tune["abc"].get<std::string>();

        sqlite3_bind_int(stmt, 1, tune["tune"].get<int>());
        sqlite3_bind_int(stmt, 2, tune["setting"].get<int>());
        sqlite3_bind_text(stmt, 3, name.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmt, 4, type.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmt, 5, mode.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmt, 6, meter.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmt, 7, abc.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(stmt, 8, abc.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(stmt, 9, 0);
        sqlite3_bind_text(stmt, 10, "", -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(stmt, 11, 0);
        
        rc = sqlite3_step(stmt);
        if (rc != SQLITE_DONE) {
            std::cerr << "SQL error: " << sqlite3_errmsg(db_connection) << std::endl;
        }
        
        sqlite3_reset(stmt);
    }
    
    sqlite3_finalize(stmt);
    sqlite3_exec(db_connection, "COMMIT", nullptr, nullptr, nullptr);
}

bool DBBuilder::load_from_file(const godot::String& filename) {
    try {
        std::string json_str = read_file(filename.utf8().get_data());
        json tunes = json::parse(json_str);
        populate_database(tunes);
        return true;
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return false;
    }
}

bool DBBuilder::load_from_url() {
    try {
        std::string json_str = fetch_json_from_url(URL);
        json tunes = json::parse(json_str);
        populate_database(tunes);
        return true;
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return false;
    }
}