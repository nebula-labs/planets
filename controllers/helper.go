package controllers

import (
	"context"

	"github.com/go-logr/logr"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	"sigs.k8s.io/controller-runtime/pkg/client"
)

var (
	DefaultPorts = []corev1.ContainerPort{
		{
			Name:          "lcd",
			ContainerPort: 1317,
		},
		{
			Name:          "p2p",
			ContainerPort: 26656,
		},
		{
			Name:          "rpc",
			ContainerPort: 26657,
		},
		{
			Name:          "prometheus",
			ContainerPort: 26660,
		},
	}
)

type Reconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

func CreateObject(obj client.Object, r *Reconciler, key types.NamespacedName, logger logr.Logger) error {
	err := r.Client.Get(context.TODO(), key, obj)

	if err != nil && errors.IsNotFound(err) {
		logger.Info("Creating a new", obj.GetObjectKind().GroupVersionKind().Kind, "Object.Namespace", key.Namespace, "Object.Name", key.Name)

		err = r.Client.Create(context.TODO(), obj)

		if err != nil {
			return err
		}

		return nil
	} else if err != nil {
		return err
	}

	return nil
}
