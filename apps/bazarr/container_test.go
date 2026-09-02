package main

import (
	"context"
	"testing"

	"github.com/nklmilojevic/containers-nix/testhelpers"
)

func Test(t *testing.T) {
	ctx := context.Background()
	image := testhelpers.GetTestImage("ghcr.io/nklmilojevic/bazarr:rolling")
	testhelpers.TestHTTPEndpoint(t, ctx, image, testhelpers.HTTPTestConfig{Port: "6767"}, nil)
}
