# -*- coding: utf-8 -*-
import re

cn_map = {
    '零':0,'〇':0,'一':1,'壹':1,'二':2,'贰':2,'两':2,'三':3,'叁':3,
    '四':4,'肆':4,'五':5,'伍':5,'六':6,'陆':6,'七':7,'柒':7,'八':8,
    '玖':8,'九':9,'十':10,'拾':10,'百':100,'佰':100,
    '千':1000,'仟':1000,'万':10000,'萬':10000
}

def parse_cn(text):
    # 支持: 三十六块七毛五 -> 36.75
    # 支持: 三十六块 -> 36
    # 支持: 七毛五 -> 0.75
    
    result = 0.0
    i = 0
    chars = list(text)
    
    while i < len(chars):
        c = chars[i]
        if c in '零〇':
            i += 1
            continue
        
        # 匹配整数部分
        int_part = ''
        while i < len(chars) and chars[i] in cn_map:
            int_part += chars[i]
            i += 1
        
        if int_part:
            val = 0
            current = 0
            for ch in int_part:
                v = cn_map.get(ch, 0)
                if v >= 10000:
                    val += current * v
                    current = 0
                elif v >= 100:
                    current = (1 if current == 0 else current) * v
                elif v >= 10:
                    current = (1 if current == 0 else current) * v
                else:
                    current = v
            val += current
            
            # 匹配小数部分
            fraction = 0.0
            while i < len(chars):
                c = chars[i]
                if c in '块元':
                    i += 1
                    # 继续读小数
                    continue
                elif c in '毛角':
                    # 角/毛 = 0.X
                    next_c = chars[i+1] if i+1 < len(chars) else ''
                    v = cn_map.get(next_c, 0)
                    fraction += v / 10.0
                    i += 2
                elif c in '分厘':
                    # 分/厘 = 0.0X
                    next_c = chars[i+1] if i+1 < len(chars) else ''
                    v = cn_map.get(next_c, 0)
                    fraction += v / 100.0
                    i += 2
                else:
                    break
            
            result += val + fraction
    
    return result

tests = [
    '三十六块七毛五',
    '三十六块',
    '七毛五',
    '七块五',
    '三十二元五角',
    '一万',
    '三十六',
]

for t in tests:
    val = parse_cn(t)
    print(f'"{t}" -> {val}')
