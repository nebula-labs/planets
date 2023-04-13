/*
Copyright 2023.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package controllers

import (
	"context"

	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	"sigs.k8s.io/controller-runtime/pkg/log"

	cosmosv1alpha1 "github.com/nebula-labs/planets/api/v1alpha1"
)

// NodeReconciler reconciles a Node object
type NodeReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

//+kubebuilder:rbac:groups=cosmos.nebula-labs.org,resources=nodes,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=cosmos.nebula-labs.org,resources=nodes/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=cosmos.nebula-labs.org,resources=nodes/finalizers,verbs=update

// Reconcile is part of the main kubernetes reconciliation loop which aims to
// move the current state of the cluster closer to the desired state.
// TODO(user): Modify the Reconcile function to compare the state specified by
// the Node object against the actual cluster state, and then
// perform operations to make the cluster state reflect the state specified by
// the user.
//
// For more details, check Reconcile and its Result here:
// - https://pkg.go.dev/sigs.k8s.io/controller-runtime@v0.13.0/pkg/reconcile
func (r *NodeReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	logger := log.FromContext(ctx)

	// create a new Node
	node := &cosmosv1alpha1.Node{}
	if err := r.Get(ctx, req.NamespacedName, node); err != nil {
		if errors.IsNotFound(err) {
			return ctrl.Result{}, nil
		}

		return ctrl.Result{}, err
	}

	// create a new Pod
	pod := newPod(node)
	if err := controllerutil.SetControllerReference(node, pod, r.Scheme); err != nil {
		return ctrl.Result{}, err
	}

	foundPod := &corev1.Pod{}
	return ctrl.Result{}, CreateObject(foundPod, (*Reconciler)(r), types.NamespacedName{Namespace: pod.Namespace, Name: pod.Name}, logger)
}

// SetupWithManager sets up the controller with the Manager.
func (r *NodeReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&cosmosv1alpha1.Node{}).
		Owns(&corev1.Pod{}).
		Complete(r)
}

func newPod(cr *cosmosv1alpha1.Node) *corev1.Pod {
	// define sensible defaults
	cr.Labels["node"] = cr.Name

	cr.Spec.Env = append(cr.Spec.Env, corev1.EnvVar{
		Name:  "CHAINID",
		Value: cr.Spec.ChainId,
	})

	// create a new Pod
	pod := &corev1.Pod{
		ObjectMeta: metav1.ObjectMeta{
			Name:      cr.Name,
			Namespace: cr.Namespace,
			Labels:    cr.Labels,
		},
		Spec: corev1.PodSpec{
			Containers: []corev1.Container{
				{
					Name:            cr.Name,
					Image:           cr.Spec.Container.Image,
					ImagePullPolicy: corev1.PullPolicy(cr.Spec.Container.ImagePullPolicy),
					Ports:           DefaultPorts,
					Env:             cr.Spec.Env,
				},
			},
		},
	}

	if (cr.Spec.DataVolume != corev1.Volume{}) {
		pod.Spec.Volumes = []corev1.Volume{cr.Spec.DataVolume}
		pod.Spec.Containers[0].VolumeMounts = []corev1.VolumeMount{
			{
				Name:      cr.Spec.DataVolume.Name,
				MountPath: cr.Spec.Container.VolumeMountPath,
			},
		}
	}

	return pod
}
