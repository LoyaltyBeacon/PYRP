<?php
// login.php
header('Content-Type: application/json');
$conn = new mysqli("localhost", "root", "heslo", "projecty");

$username = $_POST['username'] ?? '';
$token = $_POST['token'] ?? '';

$query = $conn->prepare("SELECT id FROM accounts WHERE username = ? AND web_token = ?");
$query->bind_param("ss", $username, $token);
$query->execute();
$result = $query->get_result();

if ($row = $result->fetch_assoc()) {
    echo json_encode(["status" => "ok", "user_id" => $row['id']]);
} else {
    echo json_encode(["status" => "fail"]);
}
?>
