package schemas

import (
	"log"

	v1 "github.com/OlegStrokan/schema-registry/app/schemas/parcel-event/versions/v1"
	v2 "github.com/OlegStrokan/schema-registry/app/schemas/parcel-event/versions/v2"
	"github.com/OlegStrokan/schema-registry/app/schemas/utils"
)

var SCHEMAS = make(utils.AvailableSchemas)

func InitSchemas() utils.AvailableSchemas {
	schemaV1, err := v1.CreateSchema()
	if err != nil {
		log.Fatalf("Failed to create v1 schema: %v\n", err)
	}
	schemaV2, err := v2.CreateSchema()
	if err != nil {
		log.Fatalf("Failed to create v2 schema: %v\n", err)

	}
	SCHEMAS["parcelEvent"] = map[string]utils.Schema{
		"v1": schemaV1,
		"v2": schemaV2,
	}

	return SCHEMAS
}
