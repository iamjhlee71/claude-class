param(
    [string]$ApiKey,
    [string]$OutFile
)

$prompt = "A delicious plate of Korean-style egg fried rice, glossy and savory, with fluffy separated rice grains coated in a light golden-brown soy sauce glaze. Topped with fluffy scrambled eggs, chopped green onions, and a sprinkle of sesame seeds, with a small pat of melting butter on top adding a shiny sheen. Served on a white ceramic plate on a rustic wooden table. Steam rising, warm appetizing lighting, professional food photography, 45-degree top-down angle, high detail, shallow depth of field."

$body = @{
    contents = @(
        @{
            parts = @(
                @{ text = $prompt }
            )
        }
    )
    generationConfig = @{
        responseModalities = @("IMAGE")
    }
} | ConvertTo-Json -Depth 10

$model = "gemini-2.5-flash-image"
$uri = "https://generativelanguage.googleapis.com/v1beta/models/$model`:generateContent"

$headers = @{
    "x-goog-api-key" = $ApiKey
    "Content-Type"   = "application/json"
}

try {
    $resp = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -ErrorAction Stop
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    if ($_.ErrorDetails.Message) { Write-Output $_.ErrorDetails.Message }
    exit 1
}

$parts = $resp.candidates[0].content.parts
$found = $false
foreach ($p in $parts) {
    if ($p.inlineData -and $p.inlineData.data) {
        $bytes = [Convert]::FromBase64String($p.inlineData.data)
        [IO.File]::WriteAllBytes($OutFile, $bytes)
        Write-Output "SAVED: $OutFile ($($bytes.Length) bytes), mime=$($p.inlineData.mimeType)"
        $found = $true
    } elseif ($p.text) {
        Write-Output "TEXT: $($p.text)"
    }
}
if (-not $found) { Write-Output "NO_IMAGE_RETURNED"; Write-Output ($resp | ConvertTo-Json -Depth 10) }
