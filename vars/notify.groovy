def call(String status) {
    echo "--- SHARED LIBRARY NOTIFICATION ---"
    echo "The pipeline stage has finished with status: ${status}"
    echo "Current Build: ${env.BUILD_NUMBER}"
    echo "------------------------------------"
}