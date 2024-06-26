package resolvers

import (
	schemas "github.com/OlegStrokan/schema-registry/app"
	. "github.com/linkedin/goavro/v2"
	"log"
)

func GetParcelSchemaResolver(version string) *Codec {
	schema, ok := schemas.SCHEMAS["parcelEvent"][version]
	if !ok {
		log.Fatalf("Schema version %s not found", version)
	}
	return schema.Schema
}
