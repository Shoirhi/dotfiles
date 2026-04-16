# Strap Examples

実践的な作図パターン集。全例で `BOARD_ID` と `PAGE_ID` はユーザーの実際の値に置換する。
各 JSON ペイロードは「呼び出し方法」セクションに従って `strap` ツールに渡す。

## 1. ボード・ページの基本操作

### スペース一覧からボードを探す

Step 1: スペース一覧
```json
{"tool":"listSpaces","params":{}}
```

Step 2: スペース内のボード一覧
```json
{"tool":"listBoards","auth":{"spaceId":"sp1"},"params":{}}
```

Step 3: ページ一覧
```json
{"tool":"readPages","auth":{"boardId":"b1"},"params":{}}
```

### ボード名で検索

```json
{"tool":"searchBoardsByName","auth":{"spaceId":"sp1"},"params":{"text":"Sprint"}}
```

### 新しいページを作成

```json
{"tool":"createBoardPage","auth":{"boardId":"BOARD_ID"},"params":{"name":"Architecture Diagram","description":"System architecture overview"}}
```

## 2. フローチャート

左から右に流れる 4 ステップのフローチャート。

```json
{"auth":{"boardId":"BOARD_ID"},"onError":"continue","requests":[{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"circle","x":100,"y":200,"width":160,"height":80,"text":"Start","fillColor":"#E3F2FD"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":320,"y":200,"width":200,"height":100,"text":"Process A","fillColor":"#FFFFFF"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rhombus","x":580,"y":185,"width":140,"height":130,"text":"Decision?","fillColor":"#FFF9C4"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"circle","x":800,"y":200,"width":160,"height":80,"text":"End","fillColor":"#FFCDD2"}}]}
```

レスポンスから elementId を取得後、コネクタを追加:

```json
{"auth":{"boardId":"BOARD_ID"},"requests":[{"tool":"createConnector","params":{"pageId":"PAGE_ID","fromElementId":"EL_START","toElementId":"EL_PROCESS","hasEndArrowhead":true}},{"tool":"createConnector","params":{"pageId":"PAGE_ID","fromElementId":"EL_PROCESS","toElementId":"EL_DECISION","hasEndArrowhead":true}},{"tool":"createConnector","params":{"pageId":"PAGE_ID","fromElementId":"EL_DECISION","toElementId":"EL_END","text":"Yes","hasEndArrowhead":true}}]}
```

## 3. 組織図

上から下に流れる 3 階層の組織図。

```json
{"auth":{"boardId":"BOARD_ID"},"onError":"continue","requests":[{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":300,"y":50,"width":250,"height":80,"text":"CEO","fillColor":"#1565C0","textColor":"#FFFFFF","bold":true}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":50,"y":200,"width":220,"height":70,"text":"VP Engineering","fillColor":"#42A5F5","textColor":"#FFFFFF"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":320,"y":200,"width":220,"height":70,"text":"VP Design","fillColor":"#42A5F5","textColor":"#FFFFFF"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":590,"y":200,"width":220,"height":70,"text":"VP Sales","fillColor":"#42A5F5","textColor":"#FFFFFF"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":0,"y":340,"width":180,"height":60,"text":"Frontend","fillColor":"#BBDEFB"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":200,"y":340,"width":180,"height":60,"text":"Backend","fillColor":"#BBDEFB"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":320,"y":340,"width":180,"height":60,"text":"UX Research","fillColor":"#BBDEFB"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":520,"y":340,"width":180,"height":60,"text":"UI Design","fillColor":"#BBDEFB"}}]}
```

## 4. 付箋ブレインストーミング

グリッド配置で 6 枚の付箋を並べる。

```json
{"auth":{"boardId":"BOARD_ID"},"onError":"continue","requests":[{"tool":"createText","params":{"pageId":"PAGE_ID","text":"Brainstorming: New Feature Ideas","x":50,"y":20,"width":500,"height":50,"bold":true,"fontSize":24}},{"tool":"createStickyNote","params":{"pageId":"PAGE_ID","text":"AI-powered search","x":50,"y":100,"fillColor":"#FFF9C4"}},{"tool":"createStickyNote","params":{"pageId":"PAGE_ID","text":"Real-time collaboration","x":300,"y":100,"fillColor":"#FFF9C4"}},{"tool":"createStickyNote","params":{"pageId":"PAGE_ID","text":"Template library","x":550,"y":100,"fillColor":"#C8E6C9"}},{"tool":"createStickyNote","params":{"pageId":"PAGE_ID","text":"Export to PDF","x":50,"y":330,"fillColor":"#C8E6C9"}},{"tool":"createStickyNote","params":{"pageId":"PAGE_ID","text":"Mobile app","x":300,"y":330,"fillColor":"#FFCCBC"}},{"tool":"createStickyNote","params":{"pageId":"PAGE_ID","text":"API integration","x":550,"y":330,"fillColor":"#FFCCBC"}}]}
```

## 5. 比較表 (テキスト + 図形)

2 列の比較レイアウト。

```json
{"auth":{"boardId":"BOARD_ID"},"onError":"continue","requests":[{"tool":"createText","params":{"pageId":"PAGE_ID","text":"Option A vs Option B","x":100,"y":30,"width":500,"height":50,"bold":true,"fontSize":28}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":50,"y":100,"width":300,"height":50,"text":"Option A","fillColor":"#1565C0","textColor":"#FFFFFF","bold":true}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":400,"y":100,"width":300,"height":50,"text":"Option B","fillColor":"#C62828","textColor":"#FFFFFF","bold":true}},{"tool":"createText","params":{"pageId":"PAGE_ID","text":"- Low cost\n- Easy to implement\n- Limited scalability","x":50,"y":170,"width":300,"height":120}},{"tool":"createText","params":{"pageId":"PAGE_ID","text":"- Higher cost\n- Complex setup\n- Highly scalable","x":400,"y":170,"width":300,"height":120}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":50,"y":310,"width":300,"height":40,"text":"Cost: $10k/mo","fillColor":"#E8F5E9"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":400,"y":310,"width":300,"height":40,"text":"Cost: $30k/mo","fillColor":"#FFEBEE"}}]}
```

## 6. タイムライン

水平タイムライン。罫線で軸を引き、各マイルストーンを図形で配置。

Step 1: タイムライン軸を罫線で描画
```json
{"auth":{"boardId":"BOARD_ID"},"requests":[{"tool":"createRuledLine","params":{"pageId":"PAGE_ID","startX":50,"startY":200,"endX":900,"endY":200,"lineWidth":8,"strokeColor":"#757575"}}]}
```

Step 2: マイルストーンを配置
```json
{"auth":{"boardId":"BOARD_ID"},"onError":"continue","requests":[{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"circle","x":80,"y":170,"width":80,"height":60,"text":"Q1","fillColor":"#E3F2FD","bold":true}},{"tool":"createText","params":{"pageId":"PAGE_ID","text":"Requirements\nGathering","x":50,"y":240,"width":140,"height":50,"fontSize":12}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"circle","x":280,"y":170,"width":80,"height":60,"text":"Q2","fillColor":"#E8F5E9","bold":true}},{"tool":"createText","params":{"pageId":"PAGE_ID","text":"Design &\nPrototype","x":250,"y":240,"width":140,"height":50,"fontSize":12}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"circle","x":480,"y":170,"width":80,"height":60,"text":"Q3","fillColor":"#FFF9C4","bold":true}},{"tool":"createText","params":{"pageId":"PAGE_ID","text":"Development\n& Testing","x":450,"y":240,"width":140,"height":50,"fontSize":12}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"circle","x":680,"y":170,"width":80,"height":60,"text":"Q4","fillColor":"#FFCCBC","bold":true}},{"tool":"createText","params":{"pageId":"PAGE_ID","text":"Launch &\nIteration","x":650,"y":240,"width":140,"height":50,"fontSize":12}}]}
```

## 7. マインドマップ

中央のトピックから放射状に枝を伸ばす。

Step 1: 中央ノードとサブトピック
```json
{"auth":{"boardId":"BOARD_ID"},"onError":"continue","requests":[{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"circle","x":350,"y":250,"width":200,"height":100,"text":"Product\nStrategy","fillColor":"#5C6BC0","textColor":"#FFFFFF","bold":true,"fontSize":18}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":100,"y":80,"width":180,"height":70,"text":"Market Research","fillColor":"#E8EAF6"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":620,"y":80,"width":180,"height":70,"text":"User Feedback","fillColor":"#E8EAF6"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":50,"y":420,"width":180,"height":70,"text":"Competitors","fillColor":"#E8EAF6"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":670,"y":420,"width":180,"height":70,"text":"Roadmap","fillColor":"#E8EAF6"}}]}
```

Step 2: コネクタで接続
```json
{"auth":{"boardId":"BOARD_ID"},"requests":[{"tool":"createConnector","params":{"pageId":"PAGE_ID","fromElementId":"EL_CENTER","toElementId":"EL_MARKET","strokeColor":"#5C6BC0","lineWidth":4}},{"tool":"createConnector","params":{"pageId":"PAGE_ID","fromElementId":"EL_CENTER","toElementId":"EL_FEEDBACK","strokeColor":"#5C6BC0","lineWidth":4}},{"tool":"createConnector","params":{"pageId":"PAGE_ID","fromElementId":"EL_CENTER","toElementId":"EL_COMPETITORS","strokeColor":"#5C6BC0","lineWidth":4}},{"tool":"createConnector","params":{"pageId":"PAGE_ID","fromElementId":"EL_CENTER","toElementId":"EL_ROADMAP","strokeColor":"#5C6BC0","lineWidth":4}}]}
```

## 8. SWOT 分析

2x2 グリッドの SWOT マトリクス。

```json
{"auth":{"boardId":"BOARD_ID"},"onError":"continue","requests":[{"tool":"createText","params":{"pageId":"PAGE_ID","text":"SWOT Analysis","x":150,"y":20,"width":400,"height":50,"bold":true,"fontSize":28}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":50,"y":90,"width":300,"height":220,"text":"Strengths\n\n- Strong brand\n- Skilled team\n- Loyal customers","fillColor":"#C8E6C9"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":370,"y":90,"width":300,"height":220,"text":"Weaknesses\n\n- Limited budget\n- Small market share\n- Legacy tech debt","fillColor":"#FFCDD2"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":50,"y":330,"width":300,"height":220,"text":"Opportunities\n\n- Emerging markets\n- AI integration\n- Partnership deals","fillColor":"#BBDEFB"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":370,"y":330,"width":300,"height":220,"text":"Threats\n\n- New competitors\n- Regulation changes\n- Economic downturn","fillColor":"#FFF9C4"}}]}
```

## 9. プロセスフロー (承認ワークフロー)

縦方向のプロセスフロー。分岐と合流を含む。

Step 1: ノード作成
```json
{"auth":{"boardId":"BOARD_ID"},"onError":"continue","requests":[{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"circle","x":200,"y":30,"width":160,"height":70,"text":"Submit Request","fillColor":"#E3F2FD"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":180,"y":150,"width":200,"height":80,"text":"Manager Review","fillColor":"#FFFFFF"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rhombus","x":210,"y":280,"width":140,"height":120,"text":"Approved?","fillColor":"#FFF9C4"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":400,"y":300,"width":180,"height":70,"text":"Request Changes","fillColor":"#FFCDD2"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":180,"y":450,"width":200,"height":80,"text":"Execute","fillColor":"#C8E6C9"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"circle","x":200,"y":580,"width":160,"height":70,"text":"Done","fillColor":"#E8F5E9"}}]}
```

Step 2: コネクタ追加
```json
{"auth":{"boardId":"BOARD_ID"},"requests":[{"tool":"createConnector","params":{"pageId":"PAGE_ID","fromElementId":"EL_SUBMIT","toElementId":"EL_REVIEW","hasEndArrowhead":true}},{"tool":"createConnector","params":{"pageId":"PAGE_ID","fromElementId":"EL_REVIEW","toElementId":"EL_APPROVED","hasEndArrowhead":true}},{"tool":"createConnector","params":{"pageId":"PAGE_ID","fromElementId":"EL_APPROVED","toElementId":"EL_CHANGES","text":"No","hasEndArrowhead":true}},{"tool":"createConnector","params":{"pageId":"PAGE_ID","fromElementId":"EL_CHANGES","toElementId":"EL_REVIEW","text":"Resubmit","hasEndArrowhead":true}},{"tool":"createConnector","params":{"pageId":"PAGE_ID","fromElementId":"EL_APPROVED","toElementId":"EL_EXECUTE","text":"Yes","hasEndArrowhead":true}},{"tool":"createConnector","params":{"pageId":"PAGE_ID","fromElementId":"EL_EXECUTE","toElementId":"EL_DONE","hasEndArrowhead":true}}]}
```

## 10. ノートページの作成と段落操作

ノートページを作成し、構造化されたテキストコンテンツを追加する。

Step 1: ノートページ作成
```json
{"tool":"createNotePage","auth":{"boardId":"BOARD_ID"},"params":{"title":"Meeting Notes - 2025/01/15"}}
```
→ `{"pageId":"note_page_id","name":"Meeting Notes - 2025/01/15","noteId":"note_id"}`

Step 2: 段落を追加
```json
{"auth":{"boardId":"BOARD_ID"},"onError":"continue","requests":[{"tool":"createTextParagraphs","params":{"noteId":"NOTE_ID","content":"# Agenda","order":0}},{"tool":"createTextParagraphs","params":{"noteId":"NOTE_ID","content":"## Discussion Points\n\n- Feature prioritization\n- Q2 roadmap review\n- Resource allocation","order":1}},{"tool":"createTextParagraphs","params":{"noteId":"NOTE_ID","content":"## Action Items\n\n- [ ] Draft Q2 plan by Friday\n- [ ] Schedule design review\n- [ ] Update project board","order":2}}]}
```

## 11. エレメント検索と一括更新

既存エレメントを検索し、スタイルを一括変更する。

テキストで検索:
```json
{"tool":"searchElementsByText","auth":{"boardId":"BOARD_ID"},"params":{"pageId":"PAGE_ID","text":"TODO"}}
```
→ `[{"elementId":"el1","type":"stickyNote"}, {"elementId":"el2","type":"text"}]`

見つかった付箋の色を変更:
```json
{"auth":{"boardId":"BOARD_ID"},"requests":[{"tool":"updateStickyNoteColor","params":{"elementId":"el1","fillColor":"#FFCDD2"}},{"tool":"updateTextColor","params":{"elementId":"el2","textColor":"#C62828"}}]}
```

### 型でフィルタして一覧取得

```json
{"tool":"getElementsByTypes","auth":{"boardId":"BOARD_ID"},"params":{"pageId":"PAGE_ID","types":["shape","text"]}}
```

### 日時で検索

```json
{"tool":"searchElementsByUpdatedDatetime","auth":{"boardId":"BOARD_ID"},"params":{"pageId":"PAGE_ID","startDatetime":"2025-01-01T00:00:00Z"}}
```

## 12. バッチ最適化パターン

### パターン A: 2 フェーズ作図

作成→参照が必要な場合は 2 回のリクエストに分ける。

Phase 1: ノード作成 (elementId を取得)
```json
{"auth":{"boardId":"BOARD_ID"},"requests":[{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":100,"y":100,"width":200,"height":100,"text":"Node A"}},{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":400,"y":100,"width":200,"height":100,"text":"Node B"}}]}
```

Phase 2: コネクタ接続 (Phase 1 のレスポンスから取得した elementId を使用)
```json
{"tool":"createConnector","auth":{"boardId":"BOARD_ID"},"params":{"pageId":"PAGE_ID","fromElementId":"<EL_A>","toElementId":"<EL_B>","hasEndArrowhead":true}}
```

### パターン B: stdin パイプ (CLI のみ)

```bash
cat requests.json | ~/dotfiles/claude/skills/strap/strap
```

### パターン C: 大量操作の分割

50 アイテム制限を超える場合は分割して実行する。1 バッチ 50 アイテムまで。

## 13. Z-Index 制御（前景エレメントを背景候補エレメントの前面に配置）

テキストや付箋（前景エレメント）が図形や画像（背景候補エレメント）の後ろに入り込まないよう、作成後に zIndex を調整する。

Step 1: 背景候補エレメント（図形）と前景エレメント（テキスト）を作成
```json
{"auth":{"boardId":"BOARD_ID"},"onError":"continue","requests":[{"tool":"createShape","params":{"pageId":"PAGE_ID","shapeType":"rectangle","x":100,"y":100,"width":400,"height":200,"fillColor":"#E3F2FD"}},{"tool":"createText","params":{"pageId":"PAGE_ID","text":"Title Text","x":120,"y":120,"width":360,"height":40,"bold":true,"fontSize":24}}]}
```

Step 2: zIndex を確認
```json
{"tool":"getElementIndexes","auth":{"boardId":"BOARD_ID"},"params":{"pageId":"PAGE_ID"}}
```
→ `[{"elementId":"EL_SHAPE","zIndex":10000},{"elementId":"EL_TEXT","zIndex":9500}]`

Step 3: 前景エレメント（テキスト）の zIndex が背景候補エレメント（図形）より小さい場合、前面に移動
```json
{"tool":"updateElementIndex","auth":{"boardId":"BOARD_ID"},"params":{"elementId":"EL_TEXT","zIndex":10500}}
```
