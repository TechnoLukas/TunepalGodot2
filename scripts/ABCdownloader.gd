extends Node

class_name ABCDownloader

# Base URL for thesession.org API
var session_base_url = "https://thesession.org/tunes/"
# Output file path (user directory for persistence)
var output_file_path = "res://assets/abc/thesession_tunes.abc"
# HTTP request object
var http_request = null
# Current tune ID being processed
var current_id = 1
# Maximum tune ID to try (can be set very high)
var max_id = 30000
# Delay between requests (in seconds)
var request_delay = 0.0
# Counter for successful downloads
var successful_downloads = 0
# Whether the download is currently active
var is_downloading = false
# File object for appending ABC notation
var output_file = null
# Timer for rate limiting
var timer = null
# Optional starting ID (if resuming)
var start_id = 1
# Whether to continue after encountering X consecutive 404s
var stop_after_consecutive_404s = 10
var consecutive_404_count = 0

# Signals
signal download_progress(current_id, successful_count, total_attempted)
signal download_completed(total_downloaded)
signal download_error(id, error_message)

func _ready():
    # Create the HTTP request node
    http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.connect("request_completed", self, "_on_request_completed")
    
    # Create timer for rate limiting
    timer = Timer.new()
    timer.one_shot = true
    add_child(timer)
    timer.connect("timeout", self, "_process_next_tune")

# Start downloading all tunes
func start_download(from_id = 1, to_id = 30000):
    if is_downloading:
        return
    
    # Initialize parameters
    start_id = from_id
    current_id = from_id
    max_id = to_id
    is_downloading = true
    successful_downloads = 0
    consecutive_404_count = 0
    
    # Initialize output file
    var dir = DirAccess.open(clientside.prefix + "://assets/abc/")
    var file_dir = output_file_path.get_base_dir()
    
    if not file_dir.empty() and not dir.dir_exists(file_dir):
        dir.make_dir_recursive(file_dir)
    
    # Open the file for writing (or create it)
    # If starting from 1, create a new file, otherwise append to existing
    var file_mode = FileAccess.WRITE if current_id == 1 else FileAccess.READ_WRITE
    output_file = FileAccess.open(output_file_path, file_mode)
    
    if output_file == null:
        var err = FileAccess.get_open_error()
        emit_signal("download_error", 0, "Failed to open output file: " + str(err))
        is_downloading = false
        return
    
    # If appending, move to the end of the file
    if current_id > 1:
        output_file.seek_end()
    else:
        # Add a header with creation date if starting a new file
        var date_str = Time.get_date_dict_from_system()
        var header = "# All tunes from TheSession.org\n"
        header += "# Downloaded on " + str(date_str.year) + "-" + str(date_str.month) + "-" + str(date_str.day) + "\n\n"
        output_file.store_string(header)
    
    # Start the first download
    _process_next_tune()

# Stop the download process
func stop_download():
    is_downloading = false
    if timer.is_active():
        timer.stop()
    
    if output_file != null and output_file.is_open():
        output_file.close()
    
    emit_signal("download_completed", successful_downloads)

# Process the next tune in sequence
func _process_next_tune():
    if not is_downloading or current_id > max_id:
        _finish_download()
        return
    
    # Request the ABC notation for the current tune
    var url = session_base_url + str(current_id) + "/abc"
    var headers = ["User-Agent: ABCDownloader/1.0 (respectful harvesting for personal use)"]
    var error = http_request.request(url, headers, false, HTTPClient.METHOD_GET)
    
    if error != OK:
        emit_signal("download_error", current_id, "Failed to make HTTP request: " + str(error))
        # Continue to the next tune despite the error
        current_id += 1
        timer.start(request_delay)
        return

# Handle HTTP request completion
func _on_request_completed(result, response_code, headers, body):
    if not is_downloading:
        return
    
    if result != HTTPRequest.RESULT_SUCCESS:
        emit_signal("download_error", current_id, "HTTP Request failed with result: " + str(result))
    elif response_code == 404:
        # Tune not found, might have reached the end or found a gap
        consecutive_404_count += 1
        print("Tune ID " + str(current_id) + " not found (404). Consecutive 404s: " + str(consecutive_404_count))
        
        # Check if we should stop after too many consecutive 404s
        if consecutive_404_count >= stop_after_consecutive_404s:
            print("Reached " + str(consecutive_404_count) + " consecutive 404s. Assuming end of collection.")
            _finish_download()
            return
    elif response_code == 200:
        # Reset consecutive 404 counter when we get a successful response
        consecutive_404_count = 0
        
        # Process successful response
        var abc_text = body.get_string_from_utf8()
        
        # Only store the response if it looks like valid ABC notation
        if abc_text.find("X:") != -1:
            # Add a divider between tunes with the ID for reference
            var divider = "\n\n%% Tune ID: " + str(current_id) + " %%\n"
            output_file.store_string(divider + abc_text + "\n")
            successful_downloads += 1
        else:
            emit_signal("download_error", current_id, "Response doesn't contain valid ABC notation")
    else:
        # Handle other response codes (429 Too Many Requests, etc.)
        emit_signal("download_error", current_id, "Unexpected HTTP status: " + str(response_code))
        
        # If we got rate limited, pause for a longer time
        if response_code == 429:
            timer.start(request_delay * 10)  # Wait 10x longer
            return
    
    # Update current ID and emit progress signal
    current_id += 1
    emit_signal("download_progress", current_id, successful_downloads, current_id - start_id)
    
    # Schedule the next request with a delay
    timer.start(request_delay)

# Finish the download process
func _finish_download():
    if output_file != null and output_file.is_open():
        # Add a footer with completion info
        var footer = "\n\n# End of file\n"
        footer += "# Total tunes downloaded: " + str(successful_downloads) + "\n"
        output_file.store_string(footer)
        output_file.close()
    
    is_downloading = false
    emit_signal("download_completed", successful_downloads)
    print("Download completed. Total tunes downloaded: " + str(successful_downloads))

# Set the output file path
func set_output_file(path):
    output_file_path = path
    
# Set the request delay (rate limiting)
func set_request_delay(delay):
    request_delay = delay