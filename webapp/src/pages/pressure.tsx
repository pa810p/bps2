import React, { useState } from "react"

import AppBar from "@mui/material/AppBar";
import Typography from "@mui/material/Typography";
import Container from "@mui/material/Container";
import Toolbar from "@mui/material/Toolbar";
import TextField from "@mui/material/TextField";
import Button from "@mui/material/Button";
import i18n from "i18next";
import { useTranslation } from "react-i18next";
// import { lightBlue } from '@mui/material/colors';
             
export const Pressure : React.FC = () => {
    const { t } = useTranslation('translation')

    console.log("Pressure render")

    i18n.addResource('gb', 'translation', 'pressure', 'Pressure');
    i18n.addResource('de', 'translation', 'pressure', 'Druck');
    i18n.addResource('pl', 'translation', 'pressure', 'Ciśnienie');

    const [valid, setValid] = useState(false)

    const handlePressureValidation = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
        const reg = /^\d{2,3}\/\d{2,3}\/\d{2,3}$/
        console.log(e.target.value);
        setValid(reg.test(e.target.value));
    }

//     const white = lightBlue[50];

    return (
       <AppBar position="static" style={{ background:"lightBlue" }}>
        <Container maxWidth="lg">
            <Toolbar>
                <Typography sx={{flexGrow: 1, fontWeight: 700}}>
                    {t('pressure')}
                </Typography>
            </Toolbar>
            <TextField
                onChange={(event) => handlePressureValidation(event.target.value as any)}
                label="ddd/ddd/ddd"
                variant="outlined"
                error={!valid}
                sx={{ mb: 2 }}
            />
            {/* <Button color="inherit">{t('add')}</Button> */}

            <Button style={{ background: "blue", color: "white"}}>Add</Button>
        </Container>
    </AppBar>
    )
}
