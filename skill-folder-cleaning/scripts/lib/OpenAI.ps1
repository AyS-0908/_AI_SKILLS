# OpenAI.ps1 — minimal, defensive chat/completions wrapper.
# Returns: @{ ok; content; model; in_tok; out_tok; truncated; error }
# Handles: HTTP 200 with error-in-body, finish_reason=length, 429/5xx retry,
# and model-not-found fallback.

function Invoke-OpenAIJson {
    param(
        [Parameter(Mandatory)] $Config,
        [Parameter(Mandatory)][string]$Model,
        [string]$FallbackModel,
        [Parameter(Mandatory)][string]$System,
        [Parameter(Mandatory)][string]$User,
        [int]$MaxOutTok = 1200
    )

    $key = $env:OPENAI_API_KEY
    if ([string]::IsNullOrWhiteSpace($key)) {
        return @{ ok = $false; error = "OPENAI_API_KEY not set"; content = $null; model = $Model; in_tok = 0; out_tok = 0; truncated = $false }
    }

    $url = $Config.openai.base_url.TrimEnd('/') + $Config.openai.endpoint
    $headers = @{ "Authorization" = "Bearer $key"; "Content-Type" = "application/json" }
    $modelsToTry = @($Model)
    if ($FallbackModel -and $FallbackModel -ne $Model) { $modelsToTry += $FallbackModel }

    foreach ($m in $modelsToTry) {
        $body = @{
            model           = $m
            messages        = @(
                @{ role = "system"; content = $System },
                @{ role = "user";   content = $User }
            )
            response_format = @{ type = "json_object" }
        }
        # gpt-5 family uses max_completion_tokens and rejects custom temperature.
        if ($m -like "gpt-5*") { $body.max_completion_tokens = $MaxOutTok }
        else { $body.max_tokens = $MaxOutTok; $body.temperature = 0 }
        $json = $body | ConvertTo-Json -Depth 8

        for ($attempt = 0; $attempt -le [int]$Config.openai.max_retries; $attempt++) {
            try {
                $resp = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $json `
                    -TimeoutSec ([int]$Config.openai.timeout_sec) -ErrorAction Stop

                # HTTP 200 can still carry an error object.
                if ($resp.PSObject.Properties.Name -contains "error" -and $resp.error) {
                    $msg = $resp.error.message
                    if ($msg -match "model" -and $msg -match "(does not exist|not found|access)") { break } # try fallback
                    return @{ ok = $false; error = "api error: $msg"; content = $null; model = $m; in_tok = 0; out_tok = 0; truncated = $false }
                }

                $choice = $resp.choices[0]
                $truncated = ($choice.finish_reason -eq "length")
                $content = $choice.message.content
                $inTok = if ($resp.usage) { [int]$resp.usage.prompt_tokens } else { 0 }
                $outTok = if ($resp.usage) { [int]$resp.usage.completion_tokens } else { 0 }
                return @{ ok = $true; error = $null; content = $content; model = $m; in_tok = $inTok; out_tok = $outTok; truncated = $truncated }
            }
            catch {
                $status = $null
                if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
                # 404/400 on the model => break to fallback. 429/5xx => retry. Else fail.
                if ($status -eq 404 -or $status -eq 400) { break }
                if ($status -eq 429 -or ($status -ge 500 -and $status -lt 600) -or -not $status) {
                    if ($attempt -lt [int]$Config.openai.max_retries) {
                        $wait = [int]$Config.openai.retry_base_ms * [math]::Pow(2, $attempt)
                        Start-Sleep -Milliseconds $wait
                        continue
                    }
                }
                return @{ ok = $false; error = "http $status`: $($_.Exception.Message)"; content = $null; model = $m; in_tok = 0; out_tok = 0; truncated = $false }
            }
        }
        # fell through retries or broke for fallback -> next model
    }
    return @{ ok = $false; error = "all models failed (incl. fallback)"; content = $null; model = $Model; in_tok = 0; out_tok = 0; truncated = $false }
}

# Parse the model's JSON content defensively.
function ConvertFrom-ModelJson {
    param([string]$Content)
    if ([string]::IsNullOrWhiteSpace($Content)) { return $null }
    $c = $Content.Trim()
    if ($c.StartsWith('```')) { $c = ($c -replace '^```[a-zA-Z]*', '' -replace '```$', '').Trim() }
    try { return ($c | ConvertFrom-Json) } catch { return $null }
}
