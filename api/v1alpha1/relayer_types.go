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

package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// RelayerSpec defines the desired state of Relayer
type RelayerSpec struct {
	// INSERT ADDITIONAL SPEC FIELDS - desired state of cluster
	// Important: Run "make" to regenerate code after modifying this file

	// Foo is an example field of Relayer. Edit relayer_types.go to remove/update
	Foo string `json:"foo,omitempty"`
}

// RelayerStatus defines the observed state of Relayer
type RelayerStatus struct {
	// INSERT ADDITIONAL STATUS FIELD - define observed state of cluster
	// Important: Run "make" to regenerate code after modifying this file
}

//+kubebuilder:object:root=true
//+kubebuilder:subresource:status

// Relayer is the Schema for the relayers API
type Relayer struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   RelayerSpec   `json:"spec,omitempty"`
	Status RelayerStatus `json:"status,omitempty"`
}

//+kubebuilder:object:root=true

// RelayerList contains a list of Relayer
type RelayerList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []Relayer `json:"items"`
}

func init() {
	SchemeBuilder.Register(&Relayer{}, &RelayerList{})
}
