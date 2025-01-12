# **Salsify Line Server Problem**  
###### *by João Botelho*
---

## **Running and Testing the System**

To test the API locally, follow these steps:

#### **Prerequisites**  
Ensure you have Ruby installed on your system. If not, please install it before proceeding.

#### **Steps to Run the Server**  
1. **Install Dependencies:**  
   Run the following command in your terminal from the project's root directory to set up the environment:  
   ```bash
   ./build.sh
   ```
2. **Start the Server**  
   Use the command below to start the server and process the specified file:  
   ```bash
   ./run.sh <file_path>
   ```
   Replace <file_path> with the path to the file you want to process.
   You can use the provided template file, `default_file.txt`, located in the main directory.

#### Verify the Server
Once the server starts, it will be ready to handle requests in development mode.

#### Running Tests
Run the test suite using RSpec with the following command:
```bash
bundle exec rspec
```

---

## **System Overview**

The system is designed to efficiently retrieve specific lines from large files without loading the entire file into memory. Here’s how it works:  

1. **Preprocessing Files:**  
   At server startup, the file is preprocessed to calculate line offsets, which are stored in a cache. This enables constant-time (**O(1)**) access to retrieve the offset of any line and linear-time complexity (**O(L)**) to read the actual line from the file, where **L** is the length of the line.

2. **Line Retrieval:**  
   The system exposes a `GET` endpoint at `/lines/:line_number` to fetch a specific line.  
   - **Validation:** The line number is validated (must be a positive integer). Invalid requests return a `400 Bad Request`.  
   - **Cache Lookup:** If the line is cached, it is returned immediately.  
   - **Direct Access:** If not cached, the system uses the preprocessed offsets to fetch the line from the file and caches it for 5 minute.  

3. **Response Format:**  
   The server responds with the following JSON for valid requests:  
   ```json
   {
       "line_number": 1,
       "content": "Hello World"
   }
    ```

If the requested line exceeds the file size, a `413 Content Too Large` status code is returned.

This caching mechanism minimizes disk reads, improves performance, and ensures quick response times for repeated requests.

---

## **Performance with Large Files**

The system performs efficiently regardless of file size due to its **lazy loading mechanism** (via `File.open`) and **direct offset access**. However, larger files introduce challenges:

### **Challenges**
1. **Preprocessing on Startup**  
   Preprocessing large files at startup can block the server and delay availability.

2. **Stateless and Lightweight Servers**  
   Coupling the file with the server’s runtime also increases the difficulty of scaling the service horizontally to allow for more traffic (the file would have to exist in every single machine)


### **Proposed Solutions**
- **Separate Preprocessing Service**  
  Offload file preprocessing to a dedicated service that generates offsets and stores them an in-memory cache such as Redis. This ensures the server starts up quickly and remains operational.

- **External Blob Storage (e.g., S3)**  
  Store files in external storage like S3. Fetch only the required portion of the file for the requested line, keeping the server stateless and reducing memory and bandwidth usage.

With these solutions, the system remains scalable, efficient, and capable of handling very large files.

---

## **Performance with High Traffic**

- **100 Users:** The system performs smoothly with caching and efficient line retrieval, handling moderate traffic without issues.
- **10,000 Users:** Horizontal scaling (e.g., load balancers and multiple servers) is required to distribute traffic effectively. Redis ensures consistent cache access across servers.
- **1,000,000 Users:** Advanced optimizations, such as rate limiting, pre-warming caches, and region-based load balancing, are necessary to maintain performance.

---

## **Resources Consulted**

- [Ruby File Class Documentation](https://ruby-doc.org/core-2.5.5/File.html)
- [Rails Caching Guide](https://guides.rubyonrails.org/caching_with_rails.html#low-level-caching-using-rails-cache)

---

## **Framework and Third-Party Tools Used**

- **Rails:** Chosen for its robust framework and built-in support for caching and file handling.
- **RSpec:** Preferred for its descriptive syntax and strong behavior-driven development support.
- **Rubocop:** Ensures consistent code formatting and linting.

---

## **Development Time and Future Improvements**

- **Time Spent:** Approximately 10 hours, including research, setup, coding, and testing.
- **Future Improvements:**
  - **Error Handling:** Add robust handling for edge cases like corrupted files.
  - **Pre-Warming Caches:** Pre-warm caches with some of the most frequently requested lines to improve response time for commonly accessed data.
  - **Redis Support and Separate Preprocessing Service:** Add Redis cache support to store line offsets and offload file preprocessing to a dedicated service, removing the need for preprocessing during server startup.

---

## **Additional Considerations**

- **Binary Files and File Encoding** The current implementation relies on `each_line` and `bytesize`, which assumes the file is text-based and properly delimited by line breaks. Binary files typically don’t have clear line delimiters and might contain null bytes or arbitrary data that could break the current system.
- **Rate Limiting:** Implement user or IP based rate limits to prevent abuse.
- **File Checksums:** In the case the file is going to be frequently updatd we should use checksums to detect file changes and avoid reprocessing.
- **Blob Storage:** For very large files, store them in a solution like S3 to minimize server resources and improve scalability. With this improvement, we also want to divide the file into chunks, reducing bandwidth consumption by requesting only the chunk of the file that contains the requested line.
