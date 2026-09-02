package main

import (
	"context"
	"testing"

	"github.com/nklmilojevic/containers-nix/testhelpers"
)

func Test(t *testing.T) {
	ctx := context.Background()
	image := testhelpers.GetTestImage("ghcr.io/nklmilojevic/sabnzbd:rolling")
	testhelpers.TestHTTPEndpoint(t, ctx, image, testhelpers.HTTPTestConfig{Port: "8080"}, nil)
}
