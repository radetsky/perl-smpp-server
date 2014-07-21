<?php

$senha = "smpp_179ecc508e2000c99f2d0fecb336ebcc";	// platform user password
#$cel = "5511967436475";					// alvsan's number
$cel = "5511942722431";					// alvsan's number
$m = time()."test via SMPPxHTTP converter";
$s = gethostname().'-'.time();
$senha_mini = $s;
	
$ArrayMsg = array('destino' => $cel,			// destination number
			  'msg' => $m,			// message
			  'ssid' => $s,			// ssid
			  'senha_mini' => $senha_mini);	// same as ssid
$mensagem[] = array_map(utf8_encode, $ArrayMsg); 	// Codification
	

// second array for JSON
$array[] = array('senha' => $senha,
		'simples' => 0,									
		'mensagens' => $mensagem);

// JSON function
$json = json_encode($array);

// sending JSON to our platform
$link = 'http://186.226.85.40/smsmachine/receberMultiplos.php';
if(!empty($mensagem)){
	$texto ="/usr/bin/curl -v -H 'Accept: application/json' -H 'Content-Type:application/json' -X POST -d '" . $json . "' '$link'";
	$ch = shell_exec($texto);			// shell execution of curl
	echo $ch."<br>";				// HTTP results
} else {
	echo "Vazio";					// shows empty
}
?>

