package v1alpha1

type ContainerSpec struct {
	Image           string `json:"image"`
	ImagePullPolicy string `json:"imagePullPolicy"`
	VolumeMountPath string `json:"volumeMountPath,omitempty"`
}
