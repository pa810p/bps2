import React, { useState } from "react";

import Typography from "@mui/material/Typography";
import AppBar from "@mui/material/AppBar";
import Container from "@mui/material/Container";
import Toolbar from "@mui/material/Toolbar";
import i18n from "i18next";
import { useTranslation } from "react-i18next";
import TextField from "@mui/material/TextField";
import Button from "@mui/material/Button";


export const Sugar : React.FC = () => {
    const { t } = useTranslation('translation')
    console.log("Sugar render")

    i18n.addResource('gb', 'translation', 'sugar_mg', 'Sugar [mg/dL]');
    i18n.addResource('de', 'translation', 'sugar_mg', 'Zucker [mg/dL]');
    i18n.addResource('pl', 'translation', 'sugar_mg', 'Cukier [mg/dL]');

    i18n.addResource('gb', 'translation', 'ok', 'OK');
    i18n.addResource('de', 'translation', 'ok', 'OK');
    i18n.addResource('pl', 'translation', 'ok', 'OK');

    i18n.addResource('gb', 'translation', 'comment', 'Comment');
    i18n.addResource('de', 'translation', 'comment', 'Kommentar');
    i18n.addResource('pl', 'translation', 'comment', 'Uwagi');


    const [valid, setValid] = useState(false)

//     const [sugar, setSugar] = useState();
//     const [comment, setComment] = useState();
    
    const handleSugarLevelValidation = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
        const reg = /^[0-2]?\d{2}$/;

        console.debug(e.target.value);
        setValid(reg.test(e.target.value));
    }

    const handleSubmitButton = () => {
        console.debug('handleSubmitButton');
//         if (!valid) {
//
//         } else {
//
//         }
    }

    return (
        <AppBar position="static">
        <Container maxWidth="lg">
            <Toolbar>
                <Typography sx={{flexGrow: 1, fontWeight: 700}}>
                    {t('sugar_mg')}
                </Typography>
                <TextField
                    onChange={(event) => handleSugarLevelValidation(event)}
                    label="0-299"
                    variant="outlined"
                    error={!valid}
                    sx={{ mb: 2 }}
                    />
                    {/* <Button color="inherit">{t('add')}</Button> */}
                <TextField
                    label={t('comment')}
                    variant="outlined"
                    sx={{mb: 2}}
                    />
                <Button color="inherit"
                    onClick={handleSubmitButton}
                    disabled={!valid}>
                        {t('ok')}
                </Button>
            </Toolbar>
        </Container>
        </AppBar>
    )
}