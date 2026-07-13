package main

import (
	"fmt"
	"os"
	"syscall"
)

func main() {
	fmt.Println("Preparing..")

	syscall.Mount("proc", "/proc", "proc", 0, "")
	syscall.Mount("sys", "/sys", "sysfs", 0, "")

	fmt.Println("Starting init process")
	args := []string{"/bin/sh"}

	err := syscall.Exec("/bin/sh", args, os.Environ())
	if err != nil {
		fmt.Printf("Error starting shell: %v\n", err)
	}
}
