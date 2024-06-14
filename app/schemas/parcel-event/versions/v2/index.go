package v2

import (
	"github.com/OlegStrokan/schema-registry/app/schemas/utils"
	"github.com/linkedin/goavro/v2"
)

func CreateSchema() (utils.Schema, error) {
	schemaString := `{
		"type": "record",
		"name": "ParcelEventV2",
		"fields": [
			{"name": "ID", "type": "string"},
			{"name": "ParcelNumber", "type": "string"},
			{"name": "CreatedAt", "type": "string"},
			{"name": "UpdatedAt", "type": "string"},
			{"name": "Weight", "type": "double"}
		]
	}`

	codec, err := goavro.NewCodec(schemaString)
	if err != nil {
		return utils.Schema{}, err
	}

	return utils.Schema{
		Version: 2,
		Schema:  codec,
	}, nil
}
