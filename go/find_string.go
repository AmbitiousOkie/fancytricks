package main

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: findword <search_string>")
		return
	}

	searchString := os.Args[1]
	results := make(map[string][]int)

	// Walk the file system starting at root "/"
	err := filepath.Walk("/", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			// Ignore the error and skip this file/directory
			return nil
		}
		// Only look for matches in regular files
		if !info.IsDir() {
			findStringInFile(path, searchString, results)
		}
		return nil
	})

	if err != nil {
		fmt.Println("Error walking the path:", err)
	}

	// Output the results
	for file, lines := range results {
		fmt.Printf("Found in %s on lines: %v\n", file, lines)
	}
}

func findStringInFile(path, searchString string, results map[string][]int) {
	file, err := os.Open(path)
	if err != nil {
		// Ignore files we can't open
		return
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	lineNumber := 1
	for scanner.Scan() {
		line := scanner.Text()
		if strings.Contains(line, searchString) {
			results[path] = append(results[path], lineNumber)
		}
		lineNumber++
	}

	if err := scanner.Err(); err != nil {
		// Ignore read errors
		return
	}
}
