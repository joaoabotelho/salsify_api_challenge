# Salsify Line Server Problem
###### by João Botelho

### How does your system work?

The system processes files by first preprocessing them into line offsets, which are then stored in cache at every server startup. This preprocessing step allows the system to quickly retrieve a specific line without needing to load the entire file into memory, ensuring **O(1)** constant-time access for reading lines.

The system exposes a `GET` request at `/lines/:line_number`, which fetches the content of the requested line from the file. 

1. **Line Validation**: The line number is validated to ensure it is positive and an integer. If it is not, the server returns a `400 Bad Request` status code.
2. **Cache Check**: If the line number is valid, the system checks if the line is present in the cache. 
   - If it is in the cache, the line is returned immediately.
   - If not, the system uses the preprocessed offset array to directly retrieve the line from the file and cache it for future requests.

This approach optimizes performance by caching the line for 1 minute after its first retrieval. This ensures that frequently accessed lines are quickly served from memory, reducing the need for slower disk I/O operations. By minimizing disk reads (which are more expensive than RAM accesses), the system achieves faster response times for repeated line requests.

The response will return a `200 OK` HTTP status code with the following JSON format:

```json
{
    "line_number": 1,
    "content": "Hello World"
}
```

If the requested line exceeds the total number of lines in the file, a `413 Content Too Large` status code is returned.

## How will your system perform with a 1 GB file? a 10 GB file? a 100 GB file?

The size of the file does not significantly impact the retrieval time for a specific line, as only the relevant line offset is used to directly access the line in the file, without loading the entire file into memory. This is possible because `File.open` in Ruby performs lazy loading, meaning it only loads the part of the file needed to fulfill the request. This ensures **O(1)** constant-time access for reading lines.

However, as the file size increases, there are two main challenges that arise:

1. **Preprocessing Large Files on Server Startup:**  
   For very large files, the preprocessing step (which calculates line offsets) happens on server startup. If the file is too large, this preprocessing process will block the server from fully starting until it completes. This delay could result in longer startup times and make it difficult to scale the application in environments where quick restarts are necessary.

2. **Stateless and Small Server Requirements:**  
   One of the goals of the system is to keep the server stateless and lightweight. With large files, however, this becomes challenging. Storing a large file on the same server could significantly increase the memory footprint and disk space usage. This could make the server less portable, more expensive to run, and harder to scale, especially when handling multiple large files or serving high traffic.

### Solutions:
- **File Preprocessing in a Separate Service:**  
  Instead of tying file preprocessing to server startup, we could offload this responsibility to a dedicated preprocessing service. This service would handle generating line offsets, checksums, and other metadata before the server starts. By using Redis, the offsets and metadata could be stored in a centralized cache, making them immediately accessible to the server upon startup. This approach ensures the server is fully operational from the moment it starts, without delays caused by file preprocessing, and maintains overall system resilience.

- **External Blob Storage (e.g., S3):**  
  To keep the server stateless and small, the actual file can be stored in an external blob storage solution like S3. This allows the server to remain lightweight while still being able to handle very large files. The server would fetch only the relevant portion of the file for the requested line, reducing memory consumption and bandwidth usage.  

  By using chunking techniques in S3, the server can pull only the chunk corresponding to the requested line. This minimizes bandwidth consumption while ensuring that the server doesn’t need to store large files locally.

With these solutions of leveraging caching and distributed storage solutions, the system remains scalable, stateless, and efficient even when dealing with very large files.

## How will your system perform with 100 users? 10,000 users? 1,000,000 users?

- **100 Users:**  The system can handle this number of concurrent users without significant issues. A cache is used to store frequently requested data, reducing the need for slower disk I/O operations and ensuring quick response times for repeated requests. The preprocessing of line offsets allows for efficient O(1) line retrieval, even under moderate load.

- **10,000 Users:** Performance remains acceptable, but the system may begin to show signs of strain as concurrent requests increase. To manage the load effectively, horizontal scaling with multiple server instances and a load balancer would be necessary. Using Redis as a centralized caching layer ensures consistency and quick access across distributed servers.

- **1,000,000 Users:** At this scale, further optimization is essential to maintain performance. Advanced caching strategies, such as pre-warming the cache with frequently accessed lines, and rate limiting (e.g., IP-based or user-based) would help mitigate the impact of high traffic. A distributed architecture with multiple server instances and potentially region-based load balancing would ensure that no single instance becomes a bottleneck. For larger files, offloading storage to external blob solutions like S3 would minimize local resource consumption, allowing servers to remain lightweight and stateless.


## What documentation, websites, papers, etc did you consult in doing this assignment?

- **Low Level Caching using Rails:** https://guides.rubyonrails.org/caching_with_rails.html#low-level-caching-using-rails-cache
- **File Ruby Class Docs:** https://ruby-doc.org/core-2.5.5/File.html

## What third-party libraries or other tools does the system use? How did you choose each library or framework you used?

- **Rails:** The framework of choice for rapid development, which supports caching and file handling out of the box.
- **Rubocop:** used library for consistent formatting and lint
- **RSpec:** common Rails testing library focused on behavior-driven development with a strong community and ecosystem

## How long did you spend on this exercise? If you had unlimited more time to spend on this, how would you spend it and how would you prioritize each item?

- **Time spent:** Approximately 10 hours, including setup, coding, and testing.
- **If I had unlimited time:(WIP)**
  - **Improve error handling:** Add more robust handling for edge cases, such as corrupted files or network issues.


## If you were to critique your code, what would you have to say about it?(WIP)

- **Strengths:**

- **Areas for Improvement:**
  - **Rate Limiting:** I would implement more sophisticated rate-limiting mechanisms, such as IP-based limits, to prevent abuse.
  - **Error handling:** There could be more comprehensive error handling for edge cases, like file corruption or missing data.

## Additional Considerations:

- **Checksum Cache:** If we transition to a system where it handles multiple files or the file is going to frequently updated a checksum cache is essential. By storing the checksum in a cache, the system can verify if the file has changed without needing to recompute all offsets, which helps maintain performance.
  
- **File Chunking for Large Files:** For very large files, it is not efficient to keep the entire file on the same machine as the server. Using a solution like Amazon S3 for blob storage ensures that the server can remain stateless and scale easily. By breaking the file into chunks, only the chunk relevant to the requested line is fetched, minimizing bandwidth and storage consumption.

- **Rate Limiting:** To handle high traffic and prevent overloads, implementing rate limiting would be necessary. A simple IP-based rate limiter could ensure that a single client doesn't overwhelm the server.

- **Cache Optimization:** In addition to caching offsets, caching entire lines or chunks could also improve speed for repeated requests, reducing disk I/O and speeding up the response time.

