import json
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, precision_recall_fscore_support, confusion_matrix
from sklearn.preprocessing import LabelEncoder
from skl2onnx import convert_sklearn
from skl2onnx.common.data_types import FloatTensorType

def main():
    print("Starting ML pipeline: loading Iris.csv dataset...")

    # 1. Load Iris Dataset from the user's CSV file
    df = pd.read_csv("../Iris.csv")
    print(f"Dataset shape: {df.shape}")
    print(f"Columns: {list(df.columns)}")

    # Drop the Id column (not a feature)
    if 'Id' in df.columns:
        df = df.drop(columns=['Id'])

    # Extract features and target
    feature_columns = ['SepalLengthCm', 'SepalWidthCm', 'PetalLengthCm', 'PetalWidthCm']
    X = df[feature_columns].values.astype(np.float32)

    # Encode target labels: "Iris-setosa" -> 0, "Iris-versicolor" -> 1, "Iris-virginica" -> 2
    le = LabelEncoder()
    y = le.fit_transform(df['Species'])
    class_names = [name.replace('Iris-', '').capitalize() for name in le.classes_]
    feature_names = ["sepal_length", "sepal_width", "petal_length", "petal_width"]

    print(f"Classes: {class_names}")
    print(f"Feature names: {feature_names}")
    print(f"Samples: {len(X)}")

    # 2. Train/Test Split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    # 3. Train Random Forest Classifier
    print("Training Random Forest Classifier...")
    clf = RandomForestClassifier(n_estimators=100, max_depth=5, random_state=42)
    clf.fit(X_train, y_train)

    # 4. Evaluate Model
    print("Evaluating model...")
    y_train_pred = clf.predict(X_train)
    y_test_pred = clf.predict(X_test)

    train_acc = accuracy_score(y_train, y_train_pred)
    test_acc = accuracy_score(y_test, y_test_pred)

    precision, recall, f1, _ = precision_recall_fscore_support(y_test, y_test_pred, average='weighted')
    precision_per_class, recall_per_class, f1_per_class, _ = precision_recall_fscore_support(y_test, y_test_pred, average=None)

    cm = confusion_matrix(y_test, y_test_pred)

    print(f"Train Accuracy: {train_acc:.4f}")
    print(f"Test Accuracy: {test_acc:.4f}")
    print(f"Precision: {precision:.4f}")
    print(f"Recall: {recall:.4f}")
    print(f"F1 Score: {f1:.4f}")
    print(f"Confusion Matrix:\n{cm}")

    # 5. Export model to ONNX
    print("Exporting model to ONNX format...")
    initial_type = [('float_input', FloatTensorType([None, 4]))]
    # Disable zipmap to get a plain 2D tensor of probabilities instead of a sequence of maps
    options = {id(clf): {'zipmap': False}}
    onx = convert_sklearn(clf, initial_types=initial_type, target_opset=12, options=options)

    onnx_filename = "model.onnx"
    with open(onnx_filename, "wb") as f:
        f.write(onx.SerializeToString())
    print(f"Model successfully saved to {onnx_filename}")

    # 6. Save metadata JSON
    metadata = {
        "dataset_info": {
            "dataset_name": "Iris Flower Dataset (Kaggle CSV)",
            "dataset_size": len(X),
            "features_count": len(feature_names),
            "features": feature_names,
            "classes_count": len(class_names),
            "classes": class_names
        },
        "model_info": {
            "algorithm": "Random Forest Classifier",
            "parameters": {
                "n_estimators": clf.n_estimators,
                "max_depth": clf.max_depth,
                "random_state": 42
            }
        },
        "metrics": {
            "train_accuracy": float(train_acc),
            "test_accuracy": float(test_acc),
            "precision": float(precision),
            "recall": float(recall),
            "f1_score": float(f1),
            "precision_per_class": [float(p) for p in precision_per_class],
            "recall_per_class": [float(r) for r in recall_per_class],
            "f1_score_per_class": [float(f) for f in f1_per_class],
            "confusion_matrix": cm.tolist()
        }
    }

    metadata_filename = "model_metadata.json"
    with open(metadata_filename, "w") as f:
        json.dump(metadata, f, indent=4)
    print(f"Model metadata successfully saved to {metadata_filename}")

if __name__ == "__main__":
    main()
