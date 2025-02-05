#pragma once
#include <string>
#include <memory>
#include <sqlite3.h>
#include <nlohmann/json.hpp>
#include "godot_cpp/classes/node.hpp"
#include "godot_cpp/core/class_db.hpp"

using json = nlohmann::json;

class DBBuilder : public godot::Node {
    GDCLASS(DBBuilder, godot::Node)

private:
    static constexpr const char* TABLENAME = "Tunes";
    static constexpr const char* URL = "https://raw.githubusercontent.com/adactio/TheSession-data/refs/heads/main/json/tunes.json";
    sqlite3* db_connection;
    
    // Helper methods
    static std::string fetch_json_from_url(const std::string& url);
    static std::string read_file(const std::string& filename);
    bool create_table();
    bool check_table_exists();
    void populate_database(const json& tunes);

protected:
    static void _bind_methods();

public:
    DBBuilder();
    ~DBBuilder();

    bool initialize_database();
    bool load_from_file(const godot::String& filename);
    bool load_from_url();
    sqlite3* get_database_connection() { return db_connection; }
};