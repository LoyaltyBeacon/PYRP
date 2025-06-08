<?php
// get_taxes.php
header('Content-Type: application/json');
$conn = new mysqli("localhost", "root", "heslo", "projecty");

$userId = intval($_GET['uid']);
$query = $conn->prepare("SELECT amount FROM taxes WHERE player_id = ?");
$query->bind_param("i", $userId);
$query->execute();
$result = $query->get_result();

$taxes = [];
while ($row = $result->fetch_assoc()) {
    $taxes[] = $row;
}
echo json_encode($taxes);
?>
