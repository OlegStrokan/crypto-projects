package v1

import (
	"github.com/OlegStrokan/schema-registry/app/schemas/utils"
	"github.com/linkedin/goavro/v2"
)

func CreateSchema() (utils.Schema, error) {
	schemaString := `{
		"type": "record",
		"name": "ParcelEventV1",
		"fields": [
			{"name": "ID", "type": "string"},
			{"name": "ParcelNumber", "type": "string"},
			{"name": "CreatedAt", "type": "string"},
			{"name": "UpdatedAt", "type": "string"}
		]
	}`

	codec, err := goavro.NewCodec(schemaString)
	if err != nil {
		return utils.Schema{}, err
	}

	return utils.Schema{
		Version: 1,
		Schema:  codec,
	}, nil
}
