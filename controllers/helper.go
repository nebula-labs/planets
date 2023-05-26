package controllers

import (
	"context"
	"fmt"
	"reflect"

	"github.com/go-logr/logr"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/apimachinery/pkg/util/intstr"
	"sigs.k8s.io/controller-runtime/pkg/client"
)

var (
	Ports = map[string]int32{
		"api":        1317,
		"p2p":        26656,
		"rpc":        26657,
		"prometheus": 26660,
	}

	DefaultNodePorts []corev1.ContainerPort

	DefaultServicePorts []corev1.ServicePort
)

func init() {
	DefaultNodePorts = make([]corev1.ContainerPort, 0)
	DefaultServicePorts = make([]corev1.ServicePort, 0)

	for name, port := range Ports {
		DefaultNodePorts = append(DefaultNodePorts, corev1.ContainerPort{
			Name:          name,
			ContainerPort: port,
		})

		DefaultServicePorts = append(DefaultServicePorts, corev1.ServicePort{
			Name:       name,
			Port:       port,
			TargetPort: intstr.FromString(name),
		})
	}
}

type Reconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

// CreateObject creates a new object if it does not exist
// If the object is created, it will skip the reconcile loop
func CreateObject(structure client.Object, obj client.Object, r *Reconciler, key types.NamespacedName, logger logr.Logger) (bool, error) {
	err := r.Client.Get(context.TODO(), key, structure)

	kind := reflect.TypeOf(structure).Elem().Name()

	if err != nil && errors.IsNotFound(err) {
		logger.Info(fmt.Sprintf("Creating %s with name = %s", kind, key.Name))

		err = r.Client.Create(context.TODO(), obj)

		if err != nil {
			return true, err
		}

		return true, nil
	} else if err != nil {
		return true, err
	}

	logger.Info(fmt.Sprint("Found ", kind, " with name = ", key.Name))

	return false, nil
}
