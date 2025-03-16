<?php

/**
 * ServBay Demonstration Script
 * 
 * Features:
 * - Basic "Hello World" output
 * - PHP version and module display
 * - Redis connection test with status report
 */

echo "<center><h1><span style=\"font-family:Courier New\">Hello ServBay</span>!</h1></center><br><br>";

// Display PHP version and loaded extensions
echo "<b>PHP Version:</b> " . phpversion() . "<br>";

// Output Redis connection status
echo "<b>Redis Connection Status:</b> " . checkRedisConnection() . "<br><br>";

$extensions = get_loaded_extensions();
sort($extensions);

echo "<b>Loaded Extensions (" . count($extensions) . "):</b><ul>";
echo implode("", array_map(function ($ext) {
    return "<li>$ext</li>";
}, $extensions));
echo "</ul><br>";

echo "<center>Copyright &copy; " . date("Y") . " ServBay, LLC. All rights reserved.</center>";
/**
 * Test Redis server connectivity
 * 
 * @return string Connection status message
 */
function checkRedisConnection()
{
    // Check for Redis extension availability
    if (!class_exists('Redis')) {
        return "Redis extension not installed";
    }

    try {
        $redis = new Redis();

        // Server configuration (Modify these values as needed)
        $host = '127.0.0.1';
        $port = 6379;
        $timeout = 2; // Connection timeout in seconds
        $password = null; // Add password if required

        // Establish connection
        if (!$redis->connect($host, $port, $timeout)) {
            throw new Exception("Connection failed");
        }

        // Authenticate if password is set
        if ($password && !$redis->auth($password)) {
            throw new Exception("Authentication failed");
        }

        // Perform basic write/read test
        $testKey = 'servbay_test';
        $redis->set($testKey, 'OK');
        if ($redis->get($testKey) !== 'OK') {
            throw new Exception("Data verification failed");
        }
        $redis->del($testKey);

        return "<span style=\"color:green;\">Redis connection successful!</span>";
    } catch (Exception $e) {
        return "<span style=\"color:red;\">Redis connection failed: " . $e->getMessage() . "</span>";
    }
}
