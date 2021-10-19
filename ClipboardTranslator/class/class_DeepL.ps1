class class_DeepL
{
  # public
  [String] $auth_key = ""
  [String] $source_lang = "AUTO" 
  [String] $target_lang = "JA"
  [String] $encoding = "ISO-8859-1"
  [String] $target_text = "Translate sentence."

  [String] funcTranslate(){
    If($this.source_lang -eq "AUTO"){
      $ret = Invoke-WebRequest -Body @{ auth_key="$($this.auth_key)"; text="$($this.target_text)"; target_lang="$($this.target_lang)" } https://api.deepl.com/v2/translate
    }Else{
      $ret = Invoke-WebRequest -Body @{ auth_key="$($this.auth_key)"; text="$($this.target_text)"; source_lang="$($this.source_lang)"; target_lang="$($this.target_lang)" } https://api.deepl.com/v2/translate
    }

    $json = ConvertFrom-Json $([System.Text.Encoding]::UTF8.GetString( [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($ret.Content)))
    #$json = ConvertFrom-Json $([System.Text.Encoding]::GetEncoding("Shift_JIS").GetString( [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($ret.Content)))

    return $json.translations.text
  }
}
