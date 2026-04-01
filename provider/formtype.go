package provider

import (
	"slices"

	"golang.org/x/xerrors"
)

// OptionType is a type of option that can be used in the 'type' argument of
// a parameter. These should match types as defined in terraform:
//
//	https://developer.hashicorp.com/terraform/language/expressions/types
//
// The values must be string literals, as type constraint keywords are not
// supported in providers.
type OptionType = string

const (
	OptionTypeString     OptionType = "string"
	OptionTypeNumber     OptionType = "number"
	OptionTypeBoolean    OptionType = "bool"
	OptionTypeListString OptionType = "list(string)"
)

func OptionTypes() []OptionType {
	return []OptionType{
		OptionTypeString,
		OptionTypeNumber,
		OptionTypeBoolean,
		OptionTypeListString,
	}
}

// ParameterFormType is the list of supported form types for display in
// the Lattice "create workspace" form. These form types are functional as well
// as cosmetic. Refer to formTypeTruthTable for the allowed pairings.
// For example, "multi-select" has the type "list(string)" but the option
// values are "string".
type ParameterFormType string

const (
	ParameterFormTypeDefault     ParameterFormType = ""
	ParameterFormTypeRadio       ParameterFormType = "radio"
	ParameterFormTypeSlider      ParameterFormType = "slider"
	ParameterFormTypeInput       ParameterFormType = "input"
	ParameterFormTypeDropdown    ParameterFormType = "dropdown"
	ParameterFormTypeCheckbox    ParameterFormType = "checkbox"
	ParameterFormTypeSwitch      ParameterFormType = "switch"
	ParameterFormTypeMultiSelect ParameterFormType = "multi-select"
	ParameterFormTypeTagSelect   ParameterFormType = "tag-select"
	ParameterFormTypeTextArea    ParameterFormType = "textarea"
	ParameterFormTypeError       ParameterFormType = "error"
)

// ParameterFormTypes returns all valid non-default form types.
func ParameterFormTypes() []ParameterFormType {
	return []ParameterFormType{
		// Intentionally omit ParameterFormTypeDefault — it is valid but always
		// resolved to a concrete value before use.
		ParameterFormTypeRadio,
		ParameterFormTypeSlider,
		ParameterFormTypeInput,
		ParameterFormTypeDropdown,
		ParameterFormTypeCheckbox,
		ParameterFormTypeSwitch,
		ParameterFormTypeMultiSelect,
		ParameterFormTypeTagSelect,
		ParameterFormTypeTextArea,
		ParameterFormTypeError,
	}
}

// formTypeTruthTable maps [type][optionsExist] to the allowed form_type values.
// The first value in each slice is the default when form_type is unspecified.
//
// | Type              | Options | form_type (default) | Notes                          |
// |-------------------|---------|---------------------|--------------------------------|
// | `string` `number` | Y       | `radio`             |                                |
// | `string` `number` | Y       | `dropdown`          |                                |
// | `string` `number` | N       | `input`             |                                |
// | `string`          | N       | `textarea`          |                                |
// | `number`          | N       | `slider`            | min/max validation             |
// | `bool`            | Y       | `radio`             |                                |
// | `bool`            | N       | `checkbox`          |                                |
// | `bool`            | N       | `switch`            |                                |
// | `list(string)`    | Y       | `radio`             |                                |
// | `list(string)`    | N       | `tag-select`        |                                |
// | `list(string)`    | Y       | `multi-select`      | Option values will be `string` |
var formTypeTruthTable = map[OptionType]map[bool][]ParameterFormType{
	OptionTypeString: {
		true:  {ParameterFormTypeRadio, ParameterFormTypeDropdown},
		false: {ParameterFormTypeInput, ParameterFormTypeTextArea},
	},
	OptionTypeNumber: {
		true:  {ParameterFormTypeRadio, ParameterFormTypeDropdown},
		false: {ParameterFormTypeInput, ParameterFormTypeSlider},
	},
	OptionTypeBoolean: {
		true:  {ParameterFormTypeRadio, ParameterFormTypeDropdown},
		false: {ParameterFormTypeCheckbox, ParameterFormTypeSwitch},
	},
	OptionTypeListString: {
		true:  {ParameterFormTypeRadio, ParameterFormTypeMultiSelect},
		false: {ParameterFormTypeTagSelect},
	},
}

// ValidateFormType validates the combination of parameter type, option count, and
// form_type. It also returns the effective OptionType for values/defaults, which may
// differ from paramType (e.g. multi-select uses list(string) for value but string
// for individual option values).
func ValidateFormType(paramType OptionType, optionCount int, specifiedFormType ParameterFormType) (OptionType, ParameterFormType, error) {
	optionsExist := optionCount > 0
	allowed, ok := formTypeTruthTable[paramType][optionsExist]
	if !ok || len(allowed) == 0 {
		return paramType, specifiedFormType, xerrors.Errorf("\"type\" attribute=%q is not supported, choose one of %v", paramType, OptionTypes())
	}

	if specifiedFormType == ParameterFormTypeDefault {
		specifiedFormType = allowed[0]
	}

	if !slices.Contains(allowed, specifiedFormType) {
		optionMsg := ""
		opposite := formTypeTruthTable[paramType][!optionsExist]
		if slices.Contains(opposite, specifiedFormType) {
			if optionsExist {
				optionMsg = " when options exist"
			} else {
				optionMsg = " when options do not exist"
			}
		}
		return paramType, specifiedFormType,
			xerrors.Errorf("\"form_type\" attribute=%q is not supported for \"type\"=%q%s, choose one of %v",
				specifiedFormType, paramType, optionMsg, toStrings(allowed))
	}

	// Special case: multi-select uses list(string) for the parameter value but
	// string for individual option values.
	if paramType == OptionTypeListString && specifiedFormType == ParameterFormTypeMultiSelect {
		return OptionTypeString, ParameterFormTypeMultiSelect, nil
	}

	return paramType, specifiedFormType, nil
}

func toStrings[A ~string](l []A) []string {
	var r []string
	for _, v := range l {
		r = append(r, string(v))
	}
	return r
}
