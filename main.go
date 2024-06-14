package main

import (
	"fmt"
	schemas "github.com/OlegStrokan/schema-registry/app"
)

func main() {
	availableSchemas := schemas.InitSchemas()
	fmt.Println(availableSchemas)
}
