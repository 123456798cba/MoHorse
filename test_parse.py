import re

# 模拟 Dart 的解析逻辑
cn_map = {
    '零':0,'〇':0,'一':1,'壹':1,'二':2,'贰':2,'两':2,'三':3,'叁':3,
    '四':4,'肆':4,'五':5,'伍':5,'六':6,'陆':6,'七':7,'柒':7,'八':8,
    '捌':8,'九':9,'玖':9,'十':10,'拾':10,'百':100,'佰':100,
    '千':1000,'仟':1000,'万':10000,'萬':10000
}

income_keywords = ['工资','薪资','薪水','收入','报销','奖金','红包','收款','到账','入账','进账','回款','稿费','兼职','副业','发工资','发钱','赚钱','盈利','利润','收获','得到','领到','提成','佣金']

def parse_cn_number(chars):
    result = 0
    current = 0
    for c in chars:
        v = cn_map.get(c)
        if v is None: continue
        if v >= 10000:
            result += current * v
            current = 0
        elif v >= 100:
            current = (1 if current == 0 else current) * v
        elif v >= 10:
            current = (1 if current == 0 else current) * v
        else:
            current = v
    result += current
    return result

def extract_amount(text):
    # r1: 花了/付了等 + 数字
    m = re.search(r'(?:花了|付了|用了|花费|支出|消费|花费了|支付了|用掉了)\s*(\d+\.?\d*)', text)
    if m: return float(m.group(1)), 'r1'
    
    # r2: 数字 + 块/元
    m = re.search(r'(\d+\.?\d*)\s*(?:块钱|元钱|块人民币|元人民币|块|元)(?![点时:：\d])', text)
    if m: return float(m.group(1)), 'r2'
    
    # r3: 收入/入账等 + 数字
    m = re.search(r'(?:收入|入账|到账|进账|发了|赚了|收款|领了|获得|收到|提成|佣金|工资|奖金)\s*(\d+\.?\d*)', text)
    if m: return float(m.group(1)), 'r3'
    
    # r4: 数字 + 万/千
    m = re.search(r'(\d+)\s*(?:元|块|万|千)', text)
    if m:
        amount = float(m.group(1))
        if '万' in text and amount < 100: return amount * 10000, 'r4-万'
        if '千' in text and amount < 100: return amount * 1000, 'r4-千'
        return amount, 'r4'
    
    # 中文数字
    cn_pattern = r'[零〇一二三四五六七八九十百千万壹贰叁肆伍陆柒捌玖拾佰仟萬两]+'
    m = re.search(cn_pattern, text)
    if m:
        val = parse_cn_number(m.group(0))
        return val, 'cn'
    
    return None, None

tests = [
    '今天发工资发了一万',
    '今天收入一万',
    '今天赚了五千',
    '工资到账了一万',
    '今天花了三十六块七毛五',
    '买菜花了三十六块七毛五',
    '今天花了36.75',
    '今天花了七块五',
]

print('=== 测试规则引擎 ===')
for text in tests:
    amount, rule = extract_amount(text)
    is_income = any(k in text for k in income_keywords)
    final = amount if is_income else (-(amount) if amount else None)
    print(f'[{rule}] "{text}" -> 金额:{amount}, 收入:{is_income}, 最终:{final}')

print()
print('=== 问题分析 ===')
print('1. "今天发工资发了一万" - 匹配到"工资"，但r3没有匹配到"一万"数字')
print('2. 需要在数字提取时支持中文数字')
