package backend.languages;

class JpJP 
{
    public static var languageName:String = "Japanese (Japan)";
    public static var languageCode:String = "ja-JP";
    
    public static var translations:Map<String, String> = [
        "update_available_title" => "アップデート利用可能！",
        "version_comparison" => "現在のバージョン: {1} => 新しいバージョン: {2}",
        "loading_changelog" => "変更履歴を読み込み中...",
        "update_controls" => "最新バージョンに更新するにはENTERを押してください\n正しいエンジンバージョンにいる場合はESCAPEを押してください\nこの警告はオプションメニューで無効にできます",
        "changelog_title" => "新機能:\n{1}",
        "changelog_error" => "変更履歴の読み込みエラー: {1}",

        // Gameplay
        "score_text" => "スコア: {1} | ミス: {2} | 評価: {3}",
        "score_text_instakill" => "スコア: {1} | 評価: {2}",
        "botplay" => "オート",

        // Ratings
        "rating_you_suck" => "最悪！",
        "rating_shit" => "ひどい",
        "rating_bad" => "悪い",
        "rating_bruh" => "うーん",
        "rating_meh" => "普通",
        "rating_nice" => "いいね",
        "rating_good" => "良い",
        "rating_great" => "すごい",
        "rating_sick" => "最高！",
        "rating_flawless" => "エピック！！",
        "rating_perfect" => "パーフェクト！！！",

        // Dialogues
        "dialogue_skip" => "BACKでスキップ",

        // Pause Menu
        "practice_mode" => "練習モード",
        "charting_mode" => "チャート編集",
        "blueballed" => "失敗回数: {1}",

        // Story Mode
        "week_score" => "週スコア: {1}",
        "storyname_tutorial" => "チュートリアル",
        "storyname_week1" => "ダディディアレスト",
        "storyname_week2" => "スプーキーマンス",
        "storyname_week3" => "ピコ",
        "storyname_week4" => "マミーマストマーダー",
        "storyname_week5" => "レッドスノー",
        "storyname_week6" => "ヘイティングシミュレーター ft. モーリング",
        "storyname_week7" => "タンクマン",
        "storyname_weekend1" => "期限切れの借金",

        // Freeplay
        "personal_best" => "ベストスコア: {1} ({2}%)",
        "freeplay_tip" => "SPACEで曲を試聴 / CTRLでゲームプレイ変更メニューを開く / RESETでスコアと精度をリセット。",
        "musicplayer_playing" => "再生中: {1}",
        "musicplayer_paused" => "再生中: {1} (一時停止)",
        "musicplayer_tip" => "SPACEで一時停止 / ESCで終了 / Rで曲をリセット",

        // Mods Menu
        "no_mods_installed" => "MODがインストールされていません\nBACKで終了するかMODをインストールしてください",
        "no_mods_found" => "MODが見つかりません。",
        "mod_restart" => "* このMODを移動・切替するとゲームが再起動されます。",

        // Credits
        "description_shadow_mario" => "Psych Engine チーム",

        // Reset Score/Achievement
        "reset_score" => "スコアをリセット",
        "reset_achievement" => "実績をリセット:",
        "yes" => "はい",
        "no" => "いいえ",

        // Achievements
        "achievement_friday_night_play" => "金曜日の夜のファンク",
        "description_friday_night_play" => "金曜日の...夜にプレイする。",
        "achievement_week1_nomiss" => "彼女も私をダディと呼ぶ",
        "description_week1_nomiss" => "ハードモードでウィーク1をノーミスでクリア。",
        "achievement_week2_nomiss" => "もういたずらはない",
        "description_week2_nomiss" => "ハードモードでウィーク2をノーミスでクリア。",
        "achievement_week3_nomiss" => "ヒットマンと呼べ",
        "description_week3_nomiss" => "ハードモードでウィーク3をノーミスでクリア。",
        "achievement_week4_nomiss" => "レディキラー",
        "description_week4_nomiss" => "ハードモードでウィーク4をノーミスでクリア。",
        "achievement_week5_nomiss" => "ミスレスクリスマス",
        "description_week5_nomiss" => "ハードモードでウィーク5をノーミスでクリア。",
        "achievement_week6_nomiss" => "ハイスコア！！",
        "description_week6_nomiss" => "ハードモードでウィーク6をノーミスでクリア。",
        "achievement_week7_nomiss" => "神様ちくしょう！",
        "description_week7_nomiss" => "ハードモードでウィーク7をノーミスでクリア。",
        "achievement_ur_bad" => "なんてファンクな災害だ！",
        "description_ur_bad" => "20%未満の評価で曲をクリア",
        "achievement_ur_good" => "完璧主義者",
        "description_ur_good" => "100%の評価で曲をクリア",
        "achievement_roadkill_enthusiast" => "轢き逃げ愛好家",
        "description_roadkill_enthusiast" => "部下が死ぬのを50回見る。",
        "achievement_oversinging" => "歌いすぎでは...？",
        "description_oversinging" => "アイドル状態に戻らずに10秒間歌い続ける。",
        "achievement_hype" => "ハイパーアクティブ",
        "description_hype" => "アイドル状態に戻らずに曲を完了する。",
        "achievement_two_keys" => "二人だけ",
        "description_two_keys" => "2つのキーだけで曲を完了する。",
        "achievement_toastie" => "トースターゲーマー",
        "description_toastie" => "トースターでゲームを実行してみましたか？",
        "achievement_debugger" => "デバッガー",
        "description_debugger" => "チャートエディターから「テスト」ステージをクリア。",
        "achievement_pessy_easter_egg" => "エンジンガール仲間",
        "description_pessy_easter_egg" => "へへ、私を見つけたね〜！",

        // Note Colors Menu
        "note_colors_tip" => "RESETで選択したノート部分をリセット。",
        "note_colors_hold_tip" => "{1}を押しながらRESETで選択したノートを完全リセット。",
        "note_colors_shift" => "Shift",
        "note_colors_lb" => "左ショルダーボタン",

        // Adjust Delay and Combo Menu
        "delay_beat_hit" => "ビートヒット！",
        "delay_current_offset" => "現在のオフセット: {1} ms",
        "combo_rating_offset" => "評価オフセット:",
        "combo_numbers_offset" => "数字オフセット:",
        "combo_offset" => "コンボオフセット",
        "note_delay" => "ノート/ビート遅延",
        "switch_on_accept" => "(Acceptで切替)",
        "switch_on_start" => "(Startで切替)",

        // Graphics Settings
        "description_low_quality" => "チェックすると、一部の背景詳細を無効にし、\n読み込み時間を短縮し、パフォーマンスを向上します。",
        "description_anti-aliasing" => "チェックを外すと、アンチエイリアスを無効にし、\nビジュアルが粗くなる代わりにパフォーマンスが向上します。",
        "description_shaders" => "チェックを外すと、シェーダーを無効にします。\n一部の視覚効果に使用され、弱いPCではCPU集約的です。",
        "description_gpu_caching" => "チェックすると、GPUを使用してテクスチャをキャッシュし、RAM使用量を減らします。\nグラフィックカードが悪い場合は有効にしないでください。",
        "description_framerate" => "説明の必要はないでしょう？",
        "description_fps_rework" => "有効にすると、現在のFPSがフレームレート制限を下回った場合に\nゲームが「スタッター」したり「スムーズ」になったりするのを防ぎます。",

        // Visuals Settings
        "description_note_skins" => "お好みのノートスキンを選択してください。",
        "description_note_splashes" => "お好みのノートスプラッシュバリエーションを選択するか、オフにしてください。",
        "description_note_splash_opacity" => "ノートスプラッシュの透明度はどの程度にしますか。",
        "description_hide_hud" => "チェックすると、ほとんどのHUD要素を隠します。",
        "description_time_bar" => "タイムバーに何を表示しますか？",
        "description_flashing_lights" => "点滅ライトに敏感な場合はチェックを外してください！",
        "description_camera_zooms" => "チェックを外すと、ビートヒット時にカメラがズームしません。",
        "description_score_text_grow_on_hit" => "チェックを外すと、ノートをヒットするたびに\nスコアテキストが拡大するのを無効にします。",
        "description_abbreviate_score" => "チェックすると、スコアが省略されます（例：10.00K、1.00M）。",
        "description_debug_data" => "スクロール速度、BPM、体力などのチャート情報、ステップ、ビートなどを表示。\n後者はチャートモードの場合に利用可能です。",
        "description_health_bar_opacity" => "体力バーとアイコンの透明度はどの程度にしますか。",
        "description_fps_counter" => "チェックを外すと、FPSカウンターを隠します。",
        "description_vsync" => "チェックを入れると、VSyncが有効になり、画面のティアリングが修正されますが、\nモニターのリフレッシュレートにFPSが制限されます。\n（適用するにはゲームを再起動する必要があります）",
        "description_pause_music" => "ポーズ画面でどの曲を好みますか？",
        "description_check_for_updates" => "リリース版では、ゲーム開始時にアップデートを確認するためにこれを有効にしてください。",
        "description_discord_rich_presence" => "偶発的なリークを防ぐためにチェックを外すと、Discordの「プレイ中」ボックスからアプリケーションを隠します",
        "description_combo_stacking" => "チェックを外すと、評価とコンボがスタックしなくなり、システムメモリを節約し読みやすくなります",
        "description_show_current_state" => "チェックすると、FPSカウンターが現在の状態を表示します。",
        "description_combo_and_rating_in_camgame" => "チェックすると、コンボと評価がcamHUDではなくcamGameレイヤーでレンダリングされます。",

        // Gameplay Settings
        "description_downscroll" => "チェックすると、ノートが上ではなく下に向かいます。簡単です。",
        "description_middlescroll" => "チェックすると、あなたのノートが中央に配置されます。",
        "description_opponent_notes" => "チェックを外すと、相手のノートが隠されます。",
        "description_ghost_tapping" => "チェックすると、ヒット可能なノートがない間に\nキーを押してもミスになりません。",
        "description_auto_pause" => "チェックすると、画面がフォーカスを失った場合にゲームが自動的にポーズされます。",
        "description_pop_up_score" => "チェックすると、ノートをヒットしたときに獲得したスコアが表示されます。",
        "description_disable_reset_button" => "チェックすると、リセットを押しても何もしません。",
        "description_hitsound_volume" => "ノートをヒットすると面白い「ティック！」音がします。",
        "description_rating_offset" => "「最高！」をヒットするタイミングの遅い/早いを変更\n高い値はより遅くヒットする必要があることを意味します。",
        "description_flawless_hit_window" => "エピック！をヒットできる時間をミリ秒で変更します。",
        "description_sick_hit_window" => "「最高！」をヒットできる時間を\nミリ秒で変更します。",
        "description_good_hit_window" => "「良い」をヒットできる時間を\nミリ秒で変更します。",
        "description_bad_hit_window" => "「悪い」をヒットできる時間を\nミリ秒で変更します。",
        "description_safe_frames" => "ノートを早く、または遅くヒットできる\nフレーム数を変更します。",
        "description_sustains_as_one_note" => "チェックすると、ミスした場合にホールドノートを押せなくなり、\n単一のヒット/ミスとしてカウントされます。\n古い入力システムを好む場合はチェックを外してください。",
        "description_judgement_counter" => "チェックすると、ゲーム内で判定カウンターを表示します。",
        "description_show_end_countdown" => "チェックすると、曲の終わりにカウントダウンを表示します。",
        "description_end_countdown_seconds" => "曲の終わりにカウントダウンを何秒間表示しますか。\n(10 - 30)",

        // Loading Screen
        "now_loading" => "読み込み中{1}",

        // Difficulties
        "difficulty_easy" => "簡単",
        "difficulty_normal" => "普通",
        "difficulty_hard" => "難しい",

        // Debug and Time
        "debug_speed" => "速度",
        "debug_bpm" => "BPM",
        "debug_health" => "体力",

        // PlayState - Days of the week
        "day_sunday" => "日曜日",
        "day_monday" => "月曜日",
        "day_tuesday" => "火曜日",
        "day_wednesday" => "水曜日",
        "day_thursday" => "木曜日",
        "day_friday" => "金曜日",
        "day_saturday" => "土曜日",

        // PlayState - Months
        "month_january" => "1月",
        "month_february" => "2月",
        "month_march" => "3月",
        "month_april" => "4月",
        "month_may" => "5月",
        "month_june" => "6月",
        "month_july" => "7月",
        "month_august" => "8月",
        "month_september" => "9月",
        "month_october" => "10月",
        "month_november" => "11月",
        "month_december" => "12月",

        // Rating FC (Full Combo variations)
        "clear" => "クリア",
        "sdcb" => "SDCB",
        "fc" => "FC",
        "gfc" => "GFC",
        "sfc" => "SFC",
        "rating_fc" => "FC",
        "rating_gfc" => "GFC",
        "rating_sfc" => "SFC",
        "rating_bfc" => "BFC", 
        "rating_efc" => "EFC",
        "rating_smc" => "SMC",
        "rating_lmc" => "LMC", 
        "rating_mmc" => "MMC",
        "rating_hmc" => "HMC",

        "reset_score_confirm" => "この曲のスコアと精度をリセットしてもよろしいですか？",

        "time_hours" => "時間",

        // Judgment counters  
        "judgement_flawlesss" => "エピック ",
        "judgement_sicks" => "最高   ", 
        "judgement_goods" => "良い   ",
        "judgement_bads" => "悪い   ",
        "judgement_shits" => "ひどい ",
        "judgement_misses" => "ミス   ",
        "judgement_combo" => "コンボ ",
        "judgement_max_combo" => "最大コンボ",

        "editorplaystate_section" => "セクション: {1}",
        "editorplaystate_tip" => "ESCを押してチャートエディタに戻る",
        "editorplaystate_time" => "時間: {1} / {2}",
        "editorplaystate_section_current" => "セクション: {1}",
        "editorplaystate_beat" => "ビート: {1}",
        "editorplaystate_step" => "ステップ: {1}",
        "editorplaystate_score" => "ヒット: {1} | ミス: {2}",
        
        // Language example text
        "language_example_text" => "これは日本語での例文テキストです"
    ];
}